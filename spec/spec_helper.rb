# encoding: utf-8
require "rubygems"
require "rails"
require "active_record"
require "carrierwave"
require "carrierwave/orm/activerecord"
require 'dotenv'
require 'mini_magick'

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


the_gem = Gem::Specification.find_by_name("carrierwave")
the_gem_root = the_gem.gem_dir
the_gem_lib = the_gem_root + "/lib"
the_gem_locale = the_gem_lib + "/carrierwave/locale/en.yml"
I18n.load_path << the_gem_locale


Dotenv.load

ActiveRecord::Migration.verbose = false

if [ActiveRecord::VERSION::MAJOR, ActiveRecord::VERSION::MINOR] == [4, 2]
  ActiveRecord::Base.raise_in_transactional_callbacks = true
end


# 测试的时候载入环境变量
# 或者在根目录下新建 `.env` 文件，包含 <key>=<value>
::CarrierWave.configure do |config|
  config.storage             = :qiniu
  config.qiniu_access_key    = ENV['qiniu_access_key']
  config.qiniu_secret_key    = ENV['qiniu_secret_key']

  config.qiniu_bucket        = ENV['qiniu_bucket']
  config.qiniu_bucket_domain = ENV['qiniu_bucket_domain']
end

def load_file(fname)
  File.open([Rails.root,fname].join("/"))
end


RSpec.configure do |config|

end
