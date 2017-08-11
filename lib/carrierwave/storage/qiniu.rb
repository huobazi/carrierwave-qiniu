# encoding: utf-8
require 'carrierwave'
require 'qiniu'
require 'qiniu/http'

module CarrierWave
  module Storage
    class Qiniu < Abstract

      class Connection
        def initialize(options={})
          @qiniu_bucket_domain          = options[:qiniu_bucket_domain]
          @qiniu_bucket                 = options[:qiniu_bucket]
          @qiniu_bucket_private         = options[:qiniu_bucket_private] || false
          @qiniu_access_key             = options[:qiniu_access_key]
          @qiniu_secret_key             = options[:qiniu_secret_key]
          @qiniu_block_size             = options[:qiniu_block_size] || 1024*1024*4
          @qiniu_protocol               = options[:qiniu_protocol] || "http"
          @qiniu_persistent_ops         = options[:qiniu_persistent_ops] || options[:qiniu_async_ops] || ''
          @qiniu_persistent_pipeline    = options[:qiniu_persistent_pipeline] || ''
          @qiniu_persistent_notify_url  = options[:qiniu_persistent_notify_url] || ''
          @qiniu_can_overwrite          = options[:qiniu_can_overwrite] || false
          @qiniu_expires_in             = options[:qiniu_expires_in] || options[:expires_in] || 3600
          @qiniu_up_host                = options[:qiniu_up_host]
          @qiniu_private_url_expires_in = options[:qiniu_private_url_expires_in] || 3600
          @qiniu_callback_url           = options[:qiniu_callback_url] || ''
          @qiniu_callback_body          = options[:qiniu_callback_body] || ''
          @qiniu_style_separator        = options[:qiniu_style_separator] || '-'
          @qiniu_delete_after_days      = options[:qiniu_delete_after_days] || 0
          init
        end

        def store(file, key)
          overwrite_file = nil
          overwrite_file = key if @qiniu_can_overwrite

          put_policy = ::Qiniu::Auth::PutPolicy.new(
            @qiniu_bucket,
            overwrite_file,
            @qiniu_expires_in,
            nil
          )

          put_policy.callback_url          = @qiniu_callback_url if @qiniu_callback_url.present?
          put_policy.callback_body         = @qiniu_callback_body if @qiniu_callback_body.present?
          put_policy.persistent_ops        = @qiniu_persistent_ops || @qiniu_async_ops
          put_policy.persistent_notify_url = @qiniu_persistent_notify_url if @qiniu_persistent_notify_url.present?
          put_policy.persistent_pipeline   = @persistent_pipeline

          resp_code, resp_body, resp_headers =
            ::Qiniu::Storage.upload_with_put_policy(
              put_policy,
              file.path,
              key,
              nil,
              bucket: @qiniu_bucket
          )

            if resp_code < 200 or resp_code >= 300
              raise ::CarrierWave::UploadError, "Upload failed, status code: #{resp_code}, response: #{resp_body}"
            end
        end

        #
        # @note 复制
        # @param origin [String]
        # @param target [String]
        # @return [Boolean]
        #
        def copy(origin, target)
          resp_code, resp_body, _ = ::Qiniu::Storage.copy(@qiniu_bucket, origin, @qiniu_bucket, target)
          if resp_code < 200 or resp_code >= 300
            raise ::CarrierWave::IntegrityError, "Copy failed, status code: #{resp_code}, response: #{resp_body}"
          end
        end

        def delete(key)
          ::Qiniu::Storage.delete(@qiniu_bucket, key) rescue nil
        end

        def stat(key)
          code, result, _ = ::Qiniu::Storage.stat(@qiniu_bucket, key)
          code == 200 ? result : {}
        end

        def get(path)
          code, result, _ = ::Qiniu::HTTP.get( download_url(path) )
          code == 200 ? result : nil
        end

        def download_url(path)
          encode_path = URI.escape(path) #fix chinese file name, same as encodeURIComponent in js but preserve slash '/'
          primitive_url = "#{@qiniu_protocol}://#{@qiniu_bucket_domain}/#{encode_path}"
          @qiniu_bucket_private ? \
            ::Qiniu::Auth.authorize_download_url(primitive_url, :expires_in => @qiniu_private_url_expires_in) \
            : \
            primitive_url

        end

        private

        def init
          init_qiniu_rs_connection
        end

        UserAgent = "CarrierWave-Qiniu/#{Carrierwave::Qiniu::VERSION} (#{RUBY_PLATFORM}) Ruby/#{RUBY_VERSION}".freeze

        def init_qiniu_rs_connection
          options = {
            :access_key => @qiniu_access_key,
            :secret_key => @qiniu_secret_key,
            :user_agent => UserAgent
          }
          options[:block_size] = @qiniu_block_size if @qiniu_block_size
          options[:up_host]    = @qiniu_up_host if @qiniu_up_host

          ::Qiniu.establish_connection! options

        end

      end

      class File

        def initialize(uploader, path)
          @uploader, @path = uploader, path
        end

        def path
          @path
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
          path = options.present? ? path_with_style(options) : @path
          qiniu_connection.download_url(path)
        end

        def store(file)
          qiniu_connection.store(file, @path)
        end

        def delete
          qiniu_connection.delete(@path)
        end

        def exists?
          return true if qiniu_connection.stat(path).present?
          false
        end

        #
        # @note 从指定路径复制图片
        # @param origin_path [String] 原图片路径
        # @return [Boolean]
        #
        def copy_from(origin_path)

          # 先删除目标图片，避免出现0字节文件，无法复制
          qiniu_connection.delete(@path)

          qiniu_connection.copy(origin_path, @path)

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
          file_info['mimeType'] || 'application/octet-stream'.freeze
        end

        def size
          file_info['fsize'] || 0
        end

        def extension
          path.split('.').last
        end

        private

        def qiniu_connection
          @qiniu_connection ||= begin
                                  config = {
                                    :qiniu_access_key             => @uploader.qiniu_access_key,
                                    :qiniu_secret_key             => @uploader.qiniu_secret_key,
                                    :qiniu_bucket                 => @uploader.qiniu_bucket,
                                    :qiniu_bucket_domain          => @uploader.qiniu_bucket_domain,
                                    :qiniu_bucket_private         => @uploader.qiniu_bucket_private,
                                    :qiniu_block_size             => @uploader.qiniu_block_size,
                                    :qiniu_protocol               => @uploader.qiniu_protocol,
                                    :qiniu_expires_in             => @uploader.qiniu_expires_in,
                                    :qiniu_up_host                => @uploader.qiniu_up_host,
                                    :qiniu_private_url_expires_in => @uploader.qiniu_private_url_expires_in,
                                    :qiniu_callback_url           => @uploader.qiniu_callback_url,
                                    :qiniu_callback_body          => @uploader.qiniu_callback_body,
                                    :qiniu_persistent_notify_url  => @uploader.qiniu_persistent_notify_url,
                                    :qiniu_persistent_pipeline    => @uploader.qiniu_persistent_pipeline,
                                    :qiniu_style_separator        => @uploader.qiniu_style_separator,
                                    :qiniu_delete_after_days      => @uploader.qiniu_delete_after_days
                                  }

                                  config[:qiniu_persistent_ops] = Array(@uploader.qiniu_persistent_ops || @uploader.qiniu_async_ops).join(';') rescue ''
                                  config[:qiniu_can_overwrite]  = @uploader.try :qiniu_can_overwrite rescue false

                                  Connection.new config
                                end
        end

        def file_info
          @file_info ||= qiniu_connection.stat(@path)
        end

        def path_with_style(options)
          return @path unless options

          if version = options[:version]
            "#{@path}#{@uploader.class.qiniu_style_separator}#{version}"
          elsif style = options[:style]
            "#{@path}?#{style}"
          else
            @path
          end
        end

      end

      def store!(file)
        f = ::CarrierWave::Storage::Qiniu::File.new(uploader, uploader.store_path(uploader.filename))
        if file && file.respond_to?(:copy_from_path) and file.copy_from_path
          f.copy_from file.copy_from_path
        else
          f.store(file)
        end
        f
      end

      def retrieve!(identifier)
        ::CarrierWave::Storage::Qiniu::File.new(uploader, uploader.store_path(identifier))
      end

    end
  end
end
