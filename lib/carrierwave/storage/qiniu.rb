# encoding: utf-8

begin
  require 'carrierwave'
rescue LoadError
  raise "You dot't have the 'carrierwave' gem installed"
end
begin
  require 'qiniu-rs'
rescue LoadError
  raise "You dot't have the 'qiniu-rs' gem installed"
end

module CarrierWave
  module Storage
    class Qiniu < Abstract

      class Connection
        def initialize(options={})
          @qiniu_bucket_domain = options[:qiniu_bucket_domain]
          @qiniu_bucket = options[:qiniu_bucket]
          @qiniu_access_key = options[:qiniu_access_key]
          @qiniu_secret_key = options[:qiniu_secret_key]
          init
        end
        
        def store(file, key)
          token_opts = {
            :scope => @qiniu_bucket, :expires_in => 3600 # https://github.com/qiniu/ruby-sdk/pull/15
          }
          uptoken = ::Qiniu::RS.generate_upload_token(token_opts)
          opts = {
                      :uptoken            => uptoken,
                      :file               => file.path,
                      :key                => key,
                      :bucket             => @qiniu_bucket,
                      :mime_type          => file.content_type,
                      :enable_crc32_check => true
                    }  

          ::Qiniu::RS.upload_file opts
        end

        def delete(key)
          begin            
            Qiniu::RS.delete(@qiniu_bucket, key)
          rescue Exception => e
            nil
          end
        end

        def get_public_url(key)
          if @qiniu_bucket_domain and @qiniu_bucket_domain.size > 0
            "http://#{@qiniu_bucket_domain}/#{key}"            
          else
            res = ::Qiniu::RS.get(@qiniu_bucket, key)
            if res
              res["url"]
            else
              nil
            end             
          end
        end

        private
        def init
          init_qiniu_rs_connection
          setup_publish_bucket_and_domain
        end

        def init_qiniu_rs_connection          
          return if @qiniu_rs_connection_inited
          ::Qiniu::RS.establish_connection! :access_key => @qiniu_access_key,
                                            :secret_key => @qiniu_secret_key
          
          @qiniu_rs_connection_inited = true
        end

        def setup_publish_bucket_and_domain
          ::Qiniu::RS.publish(@qiniu_bucket_domain, @qiniu_bucket)        
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
          if @uploader.qiniu_bucket_domain and @uploader.qiniu_bucket_domain.size > 0
            "http://#{@uploader.qiniu_bucket_domain}/#{key}"
          else
            qiniu_connection.get_public_url(@path)               
          end
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
                :qiniu_bucket_domain => @uploader.qiniu_bucket_domain
            }
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
