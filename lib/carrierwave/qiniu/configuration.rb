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
        add_config :qiniu_can_overwrite

        alias_config :qiniu_protocal, :qiniu_protocol
      end

      module ClassMethods
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
