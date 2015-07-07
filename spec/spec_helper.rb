# encoding: utf-8
require "rubygems"
require "rspec"
require "rspec/autorun"
require "rails"
require "active_record"
require "carrierwave"
require "carrierwave/orm/activerecord"
require 'dotenv'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..","lib"))

require "carrierwave-qiniu"

module Rails
  class <<self
    def root
      [File.expand_path(__FILE__).split('/')[0..-3].join('/'),"spec"].join("/")
    end
  end
end

Dotenv.load

ActiveRecord::Migration.verbose = false

# 测试的时候载入环境变量
# 或者在根目录下新建 `.env` 文件，包含 <key>=<value>
::CarrierWave.configure do |config|
  config.storage             = :qiniu
  config.qiniu_access_key    = ENV['qiniu_access_key']
  config.qiniu_secret_key    = ENV['qiniu_secret_key']

  config.qiniu_bucket        = ENV['qiniu_bucket']
  config.qiniu_bucket_domain = ENV['qiniu_bucket_domain']

  config.qiniu_block_size    = 4*1024*1024
  config.qiniu_protocol      = "http"
end

def load_file(fname)
  File.open([Rails.root,fname].join("/"))
end
