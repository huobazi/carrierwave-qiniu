# encoding: utf-8
require "carrierwave/storage/qiniu"
require "carrierwave/qiniu/configuration"
require "carrierwave-qiniu/version"

::CarrierWave.configure do |config|
  config.storage_engines.merge!({:qiniu => "::CarrierWave::Storage::Qiniu"})
end

::CarrierWave::Uploader::Base.send(:include, ::CarrierWave::Qiniu::Configuration)
