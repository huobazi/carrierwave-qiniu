# encoding: utf-8

module CarrierWave
  module Storage
    class QiniuFile

      attr_reader :uploader, :path
      attr_accessor :copy_from_path

      def initialize(uploader, path)
        @uploader, @path = uploader, path
      end

      ##
      # Return qiniu URl, maybe with style
      #
      # === Parameters
      # [options (Hash)] optional options hash, 图片样式 { version: :thumb } 或者 { style: "imageView2/1/w/200" }
      #
      # === Returns
      #
      # [String]
      #
      def url(options = {})
        the_path = options.present? ? path_with_style(options) : @path
        qiniu_connection.download_url(the_path)
      end

      def store(new_file)
        if new_file.is_a?(self.class)
          if new_file.respond_to?(:copy_from_path) && new_file.copy_from_path.present?
            new_file.copy_from new_file.copy_from_path
          else
            new_file.copy_to @path
          end
        else
          qiniu_connection.upload_file(new_file.path, @path)
        end
        true
      end

      def delete
        qiniu_connection.delete @path
      end

      def exists?
        return true if qiniu_connection.stat(@path).present?
        false
      end

      #
      # @note 从指定路径复制文件
      # @param origin_path [String] 原文件路径
      # @return [Boolean]
      #
      def copy_from(origin_path)
        qiniu_connection.copy(origin_path, @path)
      end

      #
      # @note 复制文件到指定路径
      # @param new_path [String] 新路径
      # @return [Boolean]
      #
      def copy_to(new_path)
        qiniu_connection.copy(@path, new_path)
        self.class.new(@uploader, new_path)
      end

      #
      # @note 移动文件到指定路径
      # @param new_path [String] 新路径
      # @return [Boolean]
      #
      def move_to(new_path)
        qiniu_connection.move(@path, new_path)
        self.class.new(@uploader, new_path)
      end

      ##
      # Reads the contents of the file from Cloud Files
      #
      # === Returns
      #
      # [String] contents of the file
      #
      def read
        qiniu_connection.get(@path) if self.size > 0
      end

      def content_type
        file_info["mimeType"] || "application/octet-stream".freeze
      end

      def size
        file_info["fsize"] || 0
      end

      def extension
        @path.split(".").last
      end

      def filename
        ::File.basename(@path)
      end

      def original_filename
        return @original_filename if @original_filename
        if @file && @file.respond_to?(:original_filename)
          @file.original_filename
        elsif @path
          ::File.basename(@path)
        end
      end

      private

      def qiniu_connection
        config = {
            :qiniu_access_key => @uploader.qiniu_access_key,
            :qiniu_secret_key => @uploader.qiniu_secret_key,
            :qiniu_bucket => @uploader.qiniu_bucket,
            :qiniu_bucket_domain => @uploader.qiniu_bucket_domain,
            :qiniu_bucket_private => @uploader.qiniu_bucket_private,
            :qiniu_block_size => @uploader.qiniu_block_size,
            :qiniu_protocol => @uploader.qiniu_protocol,
            :qiniu_expires_in => @uploader.qiniu_expires_in,
            :qiniu_up_host => @uploader.qiniu_up_host,
            :qiniu_private_url_expires_in => @uploader.qiniu_private_url_expires_in,
            :qiniu_callback_url => @uploader.qiniu_callback_url,
            :qiniu_callback_body => @uploader.qiniu_callback_body,
            :qiniu_persistent_notify_url => @uploader.qiniu_persistent_notify_url,
            :qiniu_persistent_pipeline => @uploader.qiniu_persistent_pipeline,
            :qiniu_style_separator => @uploader.qiniu_style_separator,
            :qiniu_delete_after_days => @uploader.qiniu_delete_after_days,
        }

        if (@uploader.qiniu_persistent_ops.present? && @uploader.qiniu_persistent_ops.size > 0)
          config[:qiniu_persistent_ops] = Array(@uploader.qiniu_persistent_ops).join(";")
        else
          # 适配老版本持久化参数 qiniu_async_ops
          config[:qiniu_persistent_ops] = Array(@uploader.qiniu_async_ops).join(";") if (@uploader.respond_to?(:qiniu_async_ops) && @uploader.qiniu_async_ops.present? && @uploader.qiniu_async_ops.size > 0)
        end
        config[:qiniu_can_overwrite] = @uploader.try :qiniu_can_overwrite rescue false
        @qiniu_connection = ::CarrierWave::Qiniu::Connection.new config
      end

      def file_info
        @file_info ||= qiniu_connection.stat(@path)
      end

      def path_with_style(options)
        return @path unless options
        if options.has_key?(:version)
          version = options[:version]
          return "#{@path}#{@uploader.class.qiniu_style_separator}#{version}"
        elsif options.has_key?(:style)
          style = options[:style]
          return "#{@path}?#{style}"
        else
          return @path
        end
      end
    end
  end
end