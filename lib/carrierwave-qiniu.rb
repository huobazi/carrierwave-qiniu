# encoding: utf-8
require "carrierwave-qiniu/version"
require "carrierwave/storage/qiniu"
require "carrierwave/qiniu/configuration"
require "carrierwave/qiniu/style"
require "carrierwave/uploader/base"
require "carrierwave/qiniu/railtie" if defined?(Rails)

::CarrierWave.configure do |config|
  config.storage_engines[:qiniu] = "::CarrierWave::Storage::Qiniu".freeze
end

::CarrierWave::Uploader::Base.send(:include, ::CarrierWave::Qiniu::Configuration)
::CarrierWave::Uploader::Base.send(:include, ::CarrierWave::Qiniu::Style)
