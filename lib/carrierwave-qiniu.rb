# encoding: utf-8
require "carrierwave-qiniu/version"
require "carrierwave/storage/qiniu"
require "carrierwave/qiniu/configuration"
require "carrierwave/uploader/base"

::CarrierWave.configure do |config|
  config.storage_engines[:qiniu] = "::CarrierWave::Storage::Qiniu".freeze
end

::CarrierWave::Uploader::Base.send(:include, ::CarrierWave::Qiniu::Configuration)
