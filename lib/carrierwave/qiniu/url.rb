module CarrierWave
  module Qiniu
    module Url
      # === Examples:
      #
      #     avatar.url(:version)
      #     avatar.url(:version, inline: true)
      #     avatar.url(style: 'imageView2/0/w/200')
      #
      def url(*args)
        return super if args.empty?

        if args.first.is_a? Hash
          options = args.first
          # Usage: avatar.url(style: 'imageView/0/w/200')
          if options[:style]
            url = super({})
            return "#{url}?#{options[:style]}"
          end
        else
          version = args.first.to_sym
          if qiniu_styles.key? version.to_sym
            options = args.last

            # TODO: handle private url
            url = super({})
            # Usage: avatar.url(:version, inline: true)
            if options.present? && options.is_a?(Hash) && options[:inline] && qiniu_styles[version]
              return "#{url}?#{qiniu_styles[version]}"
            else # Usage: avatar.url(:version)
              return "#{url}#{self.class.qiniu_style_separator}#{version}"
            end
          end
        end

        # Fallback to original url
        super
      end

      def qiniu_styles
        self.class.get_qiniu_styles
      end
    end
  end
end
