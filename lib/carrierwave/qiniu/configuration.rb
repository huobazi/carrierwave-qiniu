# encoding: utf-8

module CarrierWave
  module Qiniu
    module Configuration
      extend ActiveSupport::Concern
      included do
        add_config :qiniu_bucket_domain
        add_config :qiniu_bucket
        add_config :qiniu_bucket_private
        add_config :qiniu_access_key
        add_config :qiniu_secret_key
        add_config :qiniu_block_size
        add_config :qiniu_protocol
        add_config :qiniu_persistent_ops
        add_config :qiniu_persistent_notify_url
        add_config :qiniu_persistent_pipeline
        add_config :qiniu_callback_url
        add_config :qiniu_callback_body
        add_config :qiniu_can_overwrite
        add_config :qiniu_expires_in
        add_config :qiniu_up_host
        add_config :qiniu_private_url_expires_in
        add_config :qiniu_style_separator
        add_config :qiniu_style_inline
        add_config :qiniu_styles
        add_config :qiniu_delete_after_days

        alias_config :qiniu_protocal, :qiniu_protocol
        alias_config :qiniu_async_ops, :qiniu_persistent_ops

        reset_qiniu_config
      end

      module ClassMethods
        # Set default value
        def reset_qiniu_config
          configure do |config|
            config.qiniu_protocol = 'http'
            config.qiniu_bucket_private = false
            config.qiniu_block_size = 1024*1024*4
            config.qiniu_persistent_ops = ''
            config.qiniu_persistent_notify_url = ''
            config.qiniu_persistent_pipeline = ''
            config.qiniu_can_overwrite = false
            config.qiniu_private_url_expires_in = 3600
            config.qiniu_callback_url = ''
            config.qiniu_callback_body = ''
            config.qiniu_persistent_notify_url = ''
            config.qiniu_style_separator = '-'
            config.qiniu_style_inline = false
            config.qiniu_delete_after_days = 0
          end
        end

        def alias_config(new_name, old_name)
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def self.#{new_name}(value=nil)
            self.#{old_name}(value)
          end

          def self.#{new_name}=(value)
            self.#{old_name}=(value)
          end

          def #{new_name}
          #{old_name}
          end
          RUBY
        end
      end
    end
  end
end
