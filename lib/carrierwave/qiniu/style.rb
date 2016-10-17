require 'carrierwave/qiniu/url'

module CarrierWave
  module Qiniu
    module Style
      extend ActiveSupport::Concern

      class_methods do
        # === Examples:
        #
        #    qiniu_styles [:thumbnail, :large]
        #    qiniu_styles :thumbnail => 'imageView/0/w/200', :large => 'imageView/0/w/800'
        #    qiniu_styles
        #
        def qiniu_styles(versions = nil)
          # Override #url method when set styles, otherwise still default strategy.
          unless include? ::CarrierWave::Qiniu::Url
            send(:include, ::CarrierWave::Qiniu::Url)
          end

          @qiniu_styles = {}
          if versions.is_a? Array
            @qiniu_styles = versions.map { |version| [version.to_sym, nil] }.to_h
          elsif versions.is_a? Hash
            @qiniu_styles = versions.symbolize_keys
          end
        end

        def get_qiniu_styles
          @qiniu_styles
        end
      end
    end
  end
end
