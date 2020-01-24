# encoding: utf-8

require "carrierwave"
require "carrierwave/qiniu/version"
require "carrierwave/qiniu/configuration"
require "carrierwave/qiniu/connection"
require "carrierwave/qiniu/style"
require "carrierwave/qiniu/railtie" if defined?(Rails)
require "carrierwave/storage/qiniu"
require "carrierwave/storage/qiniu_file"
require "qiniu"
require "qiniu/http"

::CarrierWave.configure do |config|
  config.storage_engines[:qiniu] = "::CarrierWave::Storage::Qiniu".freeze
end

::CarrierWave::Uploader::Base.send(:include, ::CarrierWave::Qiniu::Configuration)
::CarrierWave::Uploader::Base.send(:include, ::CarrierWave::Qiniu::Style)
