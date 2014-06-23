# encoding: utf-8
require 'carrierwave'
require 'qiniu'

module CarrierWave
  module Storage
    class Qiniu < Abstract

      class Connection
        def initialize(options={})
          @qiniu_bucket_domain = options[:qiniu_bucket_domain]
          @qiniu_bucket        = options[:qiniu_bucket]
          @qiniu_bucket_private= options[:qiniu_bucket_private] || false
          @qiniu_access_key    = options[:qiniu_access_key]
          @qiniu_secret_key    = options[:qiniu_secret_key]
          @qiniu_block_size    = options[:qiniu_block_size] || 1024*1024*4
          @qiniu_protocol      = options[:qiniu_protocol] || "http"
          @qiniu_async_ops     = options[:qiniu_async_ops] || ''
          @qiniu_can_overwrite = options[:qiniu_can_overwrite] || false
          init
        end

        def store(file, key)
          qiniu_upload_scope = @qiniu_bucket
          qiniu_upload_scope = @qiniu_bucket + ':' + key if @qiniu_can_overwrite

          put_policy = ::Qiniu::Auth::PutPolicy.new(
            @qiniu_bucket,
            key,
            3600
          )

          code, result, response_headers = ::Qiniu::Storage.upload_with_put_policy(
            put_policy,
            file.path,
            key
          )

        end

        def delete(key)
          begin
            ::Qiniu::Storage.delete(@qiniu_bucket, key)
          rescue Exception => e
            nil
          end
        end

        def download_url(path)
          encode_path = URI.escape(path, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) #fix chinese file name, same as encodeURIComponent in js
          primitive_url = "#{@qiniu_protocol}://#{@qiniu_bucket_domain}/#{encode_path}"
          @qiniu_bucket_private ? ::Qiniu::Auth.authorize_download_url(primitive_url) : primitive_url
        end

        private

        def init
          init_qiniu_rs_connection
        end

        def init_qiniu_rs_connection
          return if @qiniu_rs_connection_inited

          ::Qiniu.establish_connection! :access_key => @qiniu_access_key,
            :secret_key => @qiniu_secret_key,
            :block_size => @qiniu_block_size

          @qiniu_rs_connection_inited = true
        end

      end

      class File

        def initialize(uploader, path)
          @uploader, @path = uploader, path
        end

        def path
          @path
        end

        def url
          qiniu_connection.download_url(@path)
        end

        def store(file)
          qiniu_connection.store(file, @path)
        end

        def delete
          qiniu_connection.delete(@path)
        end

        private

        def qiniu_connection
          if @qiniu_connection
            @qiniu_connection
          else
            config = {
              :qiniu_access_key    => @uploader.qiniu_access_key,
              :qiniu_secret_key    => @uploader.qiniu_secret_key,
              :qiniu_bucket        => @uploader.qiniu_bucket,
              :qiniu_bucket_domain => @uploader.qiniu_bucket_domain,
              :qiniu_bucket_private=> @uploader.qiniu_bucket_private,
              :qiniu_block_size    => @uploader.qiniu_block_size,
              :qiniu_protocol      => @uploader.qiniu_protocol
            }

            if @uploader.respond_to?(:qiniu_async_ops) and !@uploader.qiniu_async_ops.nil? and @uploader.qiniu_async_ops.size > 0
              if @uploader.qiniu_async_ops.is_a?(Array)
                config.merge!(:qiniu_async_ops => @uploader.qiniu_async_ops.join(';'))
              else
                config.merge!(:qiniu_async_ops => @uploader.qiniu_async_ops)
              end
            end

            if @uploader.respond_to?(:qiniu_can_overwrite) and !@uploader.qiniu_can_overwrite.nil?
              if @uploader.qiniu_can_overwrite.is_a?(TrueClass) or @uploader.is_a?(FalseClass)
                config.merge!(:qiniu_can_overwrite => @uploader.qiniu_can_overwrite)
              else
                config.merge!(:qiniu_can_overwrite => false)
              end
            end

            @qiniu_connection ||= Connection.new config
          end
        end

      end

      def store!(file)
        f = ::CarrierWave::Storage::Qiniu::File.new(uploader, uploader.store_path(uploader.filename))
        f.store(file)
        f
      end

      def retrieve!(identifier)
        ::CarrierWave::Storage::Qiniu::File.new(uploader, uploader.store_path(identifier))
      end

    end
  end
end
