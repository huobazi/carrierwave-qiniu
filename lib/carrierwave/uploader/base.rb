#encoding: utf-8
module CarrierWave

  class SanitizedFile

    attr_accessor :copy_from_path

  end

  module Uploader
    module Cache

      alias_method :old_cache!, :cache!

      def cache!(new_file = sanitized_file)

        old_cache! new_file

        if new_file.kind_of? CarrierWave::Storage::Qiniu::File
          @file.copy_from_path = new_file.path
        elsif new_file.kind_of? CarrierWave::Uploader::Base
          return unless new_file.file.present?
          @file.copy_from_path = new_file.file.path
        end

      end
    end

  end


end
