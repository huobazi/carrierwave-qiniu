# encoding: utf-8


module CarrierWave
  module Qiniu
    class Connection
      StatusOK = 200
      @@connection_established = false

      def initialize(options = {})
        @qiniu_bucket_domain = options[:qiniu_bucket_domain]
        @qiniu_bucket = options[:qiniu_bucket]
        @qiniu_bucket_private = options[:qiniu_bucket_private] || false
        @qiniu_access_key = options[:qiniu_access_key]
        @qiniu_secret_key = options[:qiniu_secret_key]
        @qiniu_block_size = options[:qiniu_block_size] || 1024 * 1024 * 4
        @qiniu_protocol = options[:qiniu_protocol] || "http"
        @qiniu_persistent_ops = options[:qiniu_persistent_ops] || options[:qiniu_async_ops] || ""
        @qiniu_persistent_pipeline = options[:qiniu_persistent_pipeline] || ""
        @qiniu_persistent_notify_url = options[:qiniu_persistent_notify_url] || ""
        @qiniu_can_overwrite = options[:qiniu_can_overwrite] || false
        @qiniu_expires_in = options[:qiniu_expires_in] || options[:expires_in] || 3600
        @qiniu_up_host = options[:qiniu_up_host]
        @qiniu_private_url_expires_in = options[:qiniu_private_url_expires_in] || 3600
        @qiniu_callback_url = options[:qiniu_callback_url] || ""
        @qiniu_callback_body = options[:qiniu_callback_body] || ""
        @qiniu_style_separator = options[:qiniu_style_separator] || "-"
        @qiniu_delete_after_days = options[:qiniu_delete_after_days] || 0
        init
      end

      def upload_file(file_path, key)
        overwrite_file = nil
        overwrite_file = key if @qiniu_can_overwrite

        put_policy = ::Qiniu::Auth::PutPolicy.new(
            @qiniu_bucket,
            overwrite_file,
            @qiniu_expires_in,
            nil
        )

        put_policy.callback_url = @qiniu_callback_url if @qiniu_callback_url.present?
        put_policy.callback_body = @qiniu_callback_body if @qiniu_callback_body.present?
        put_policy.persistent_ops = @qiniu_persistent_ops
        put_policy.persistent_notify_url = @qiniu_persistent_notify_url if @qiniu_persistent_notify_url.present?
        put_policy.persistent_pipeline = @qiniu_persistent_pipeline

        resp_code, resp_body, resp_headers =
            ::Qiniu::Storage.upload_with_put_policy(put_policy, file_path, key, nil, bucket: @qiniu_bucket)

        raise ::Qiniu::UploadFailedError.new(resp_code, resp_body) if resp_code != StatusOK

        resp_body
      end

      #
      # 复制
      # @param origin [String]
      # @param target [String]
      # @return [Boolean]
      #
      def copy(origin, target)
        success = ::Qiniu.copy(
            @qiniu_bucket,
            origin,
            @qiniu_bucket,
            target
        )
        success
      end

      #
      # 移动
      # @param origin [String]
      # @param target [String]
      # @return [Boolean]
      #
      def move(origin, target)
        success = ::Qiniu.move(
            @qiniu_bucket,
            origin, # 源资源名
            @qiniu_bucket,
            target # 目标资源名
        )
        success
      end

      #
      # 删除
      # @param  key [String]
      # @return [Boolean]
      #
      def delete(key)
        success = ::Qiniu.delete(
            @qiniu_bucket,
            key
        )
        success
      end

      #
      # 获取文件信息
      # @param  key [String]
      # @return [Hash]
      #
      def stat(key)
        info = ::Qiniu.stat(
            @qiniu_bucket, # 存储空间
            key # 资源名
        )
        info
      end

      def get(path)
        code, result, _ = ::Qiniu::HTTP.get(download_url(path))
        code == 200 ? result : nil
      end

      def download_url(path)
        encode_path = path_escape(path)
        primitive_url = "#{@qiniu_protocol}://#{@qiniu_bucket_domain}/#{encode_path}"
        @qiniu_bucket_private ? ::Qiniu::Auth.authorize_download_url(primitive_url, :expires_in => @qiniu_private_url_expires_in) : primitive_url
      end

      private

      def init
        establish_connection! unless @@connection_established
        @@connection_established = true
      end

      UserAgent = "CarrierWave-Qiniu/#{Carrierwave::Qiniu::VERSION} (#{RUBY_PLATFORM}) Ruby/#{RUBY_VERSION}".freeze

      def establish_connection!
        options = {
            :access_key => @qiniu_access_key,
            :secret_key => @qiniu_secret_key,
            :user_agent => UserAgent,
        }
        options[:block_size] = @qiniu_block_size if @qiniu_block_size
        options[:up_host] = @qiniu_up_host if @qiniu_up_host
        ::Qiniu.establish_connection! options
      end

      #fix chinese file name, same as encodeURIComponent in js but preserve slash '/'
      def path_escape(value)
        ::URI::DEFAULT_PARSER.escape value
      end
    end
  end
end
