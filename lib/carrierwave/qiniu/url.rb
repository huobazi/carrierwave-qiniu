module CarrierWave
  module Qiniu
    module Url

      ##
      # === Examples:
      #
      #     avatar.url(:version)
      #     avatar.url(:version, inline: true)
      #     avatar.url(style: 'imageView2/0/w/200')
      #
      def url(*args)
        return super if args.empty?

        # return nil if blank
        return if file.blank?

        # Usage: avatar.url(style: 'imageView/0/w/200')
        if args.first.is_a? Hash
          if style = args.first[:style]
            return file.url(style: style)
          end
        else
          # Usage: avatar.url(version, options)
          version = args.first.to_sym
          if styles.has_key? version
            options = args.last

            # Usage: avatar.url(:version, inline: true)
            url_options = if options.present? && options.is_a?(Hash) && options[:inline] && styles[version]
                            { style: styles[version] }
                          else
                            # global inline mode
                            if self.class.qiniu_style_inline && styles[version]
                              { style: styles[version] }
                            else
                              # Usage: avatar.url(:version)
                              { version: version }
                            end
                          end
            return file.url(url_options) if url_options
          end
        end

        # Fallback to original url
        super
      end

      def styles
        self.class.get_qiniu_styles
      end
    end
  end
end
