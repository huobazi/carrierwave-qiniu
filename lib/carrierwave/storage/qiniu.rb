# encoding: utf-8
module CarrierWave
  module Storage
    class Qiniu < Abstract
      def store!(file)
        QiniuFile.new(uploader, uploader.store_path).tap do |qiniu_file|
          qiniu_file.store(file)
        end
      end

      def cache!(file)
        QiniuFile.new(uploader, uploader.cache_path).tap do |qiniu_file|
          qiniu_file.store(file)
        end
      end

      def retrieve!(identifier)
        QiniuFile.new(uploader, uploader.store_path(identifier))
      end

      def retrieve_from_cache!(identifier)
        QiniuFile.new(uploader, uploader.cache_path(identifier))
      end

      ##
      # Deletes a cache dir
      #
      def delete_dir!(path)
        base_dir = Rack::Utils.escape_path(path)
        QiniuFile.new(uploader, uploader.store_path).tap do |qiniu_file|
          qiniu_file.send(:qiniu_connection).batch_delete(base_dir)
        end
      end

      def clean_cache!(seconds)
        # 如果缓存目录在云端,建议使用七牛云存储的生命周期设置, 以减少主动 API 调用次数
        raise 'Use Qiniu Object Lifecycle Management to clean the cache'
      end
    end
  end
end
