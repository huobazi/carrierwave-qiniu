# encoding: utf-8
require 'carrierwave'
require 'qiniu'
require 'qiniu/http'

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
          @qiniu_expires_in    = options[:qiniu_expires_in] || options[:expires_in] || 3600
          @qiniu_up_host       = options[:qiniu_up_host]
          @qiniu_private_url_expires_in = options[:qiniu_private_url_expires_in] || 3600
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
          put_policy.persistent_ops = @qiniu_async_ops

          code, result, response_headers = ::Qiniu::Storage.upload_with_put_policy(
            put_policy,
            file.path,
            key
          )

        end

        def delete(key)
          begin
            ::Qiniu::Storage.delete(@qiniu_bucket, key)
          rescue Exception
            nil
          end
        end

        def stat(key)
          code, result, response_headers = ::Qiniu::Storage.stat(@qiniu_bucket, key)
          code == 200 ? result : {}
        end

        def get(path)
          code, result, response_headers = ::Qiniu::HTTP.get( download_url(path) )
          code == 200 ? result : nil
        end

        def download_url(path)
          private_url_args = {}
          encode_path = URI.escape(path, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) #fix chinese file name, same as encodeURIComponent in js
          primitive_url = "#{@qiniu_protocol}://#{@qiniu_bucket_domain}/#{encode_path}"
          private_url_args.merge!(expires_in: @qiniu_private_url_expires_in) if @qiniu_bucket_private
          @qiniu_bucket_private ? ::Qiniu::Auth.authorize_download_url(primitive_url, private_url_args) : primitive_url
        end

        private

        def init
          init_qiniu_rs_connection
        end

        def init_qiniu_rs_connection
          options = {
            :access_key => @qiniu_access_key,
            :secret_key => @qiniu_secret_key,
            :user_agent => 'CarrierWave-Qiniu/' + Carrierwave::Qiniu::VERSION + ' ('+RUBY_PLATFORM+')' + ' Ruby/'+ RUBY_VERSION
          }
          options.merge(:block_size => @qiniu_block_size) if @qiniu_block_size
          options.merge(:up_host    => @qiniu_up_host) if @qiniu_up_host

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

        def url
          qiniu_connection.download_url(@path)
        end

        def store(file)
          qiniu_connection.store(file, @path)
        end

        def delete
          qiniu_connection.delete(@path)
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
          file_info['mimeType'] || 'application/octet-stream'
        end

        def size
          file_info['fsize'] || 0
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
              :qiniu_protocol      => @uploader.qiniu_protocol,
              :qiniu_expires_in    => @uploader.qiniu_expires_in,
              :qiniu_up_host       => @uploader.qiniu_up_host,
              :qiniu_private_url_expires_in => @uploader.qiniu_private_url_expires_in
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

        def file_info
          @file_info ||= qiniu_connection.stat(@path)
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
