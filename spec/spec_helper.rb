# encoding: utf-8
require "bundler/setup"
require "carrierwave-qiniu"
require "active_record"
require "carrierwave"
require "carrierwave/orm/activerecord"
require "mini_magick"


def open_fixtures_file(fname)
  File.open([Rails.root, "fixtures/#{fname}"].join("/"))
end

def source_environment_file!
  return unless File.exist?('.env')

  File.readlines('.env').each do |line|
    key, value = line.split('=')
    ENV[key] = value.chomp
  end
end

module Rails
  class << self
    def root
      [File.expand_path(__FILE__).split("/")[0..-3].join("/"), "spec"].join("/")
    end
  end
end

ActiveSupport.on_load :active_record do
  require "carrierwave/orm/activerecord"
end

the_gem = Gem::Specification.find_by_name("carrierwave")
the_gem_root = the_gem.gem_dir
the_gem_lib = the_gem_root + "/lib"
the_gem_locale = the_gem_lib + "/carrierwave/locale/en.yml"
I18n.load_path << the_gem_locale

ActiveRecord::Migration.verbose = false

if [ActiveRecord::VERSION::MAJOR, ActiveRecord::VERSION::MINOR] == [4, 2]
  ActiveRecord::Base.raise_in_transactional_callbacks = true
end

source_environment_file!


# 测试的时候载入环境变量
# 或者在根目录下新建 `.env` 文件，包含 <key>=<value>
::CarrierWave.configure do |config|
  config.storage             = :qiniu
  config.qiniu_access_key    = ENV["qiniu_access_key"]
  config.qiniu_secret_key    = ENV["qiniu_secret_key"]

  config.qiniu_bucket        = ENV["qiniu_bucket"]
  config.qiniu_bucket_domain = ENV["qiniu_bucket_domain"]
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
