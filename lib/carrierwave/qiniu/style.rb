require 'carrierwave/qiniu/url'

module CarrierWave
  module Qiniu
    module Style
      extend ActiveSupport::Concern

      class_methods do
        # === Examples:
        #
        #    CarrierWave.configure do |config|
        #      config.qiniu_styles = [:thumbnail, :large]
        #      # or
        #      config.qiniu_styles = {:thumbnail => 'imageView/0/w/200', :large => 'imageView/0/w/800'}
        #    end
        #
        #    # Eanble qiniu styles otherwise default version processing
        #    use_qiniu_styles
        #
        def use_qiniu_styles

          # Override #url method when set styles, otherwise still default strategy.
          unless include? ::CarrierWave::Qiniu::Url
            send(:include, ::CarrierWave::Qiniu::Url)
          end

          @_qiniu_styles = {}
          if self.qiniu_styles
            # Set default styles
            @_qiniu_styles = parse_qiniu_styles(self.qiniu_styles)
          end
        end

        def get_qiniu_styles
          @_qiniu_styles
        end

        private
        def parse_qiniu_styles(styles)
          if styles.is_a? Array
            styles.map { |version| [version.to_sym, nil] }.to_h
          elsif styles.is_a? Hash
            styles.symbolize_keys
          end
        end
      end
    end
  end
end
