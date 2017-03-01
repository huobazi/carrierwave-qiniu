# -*- encoding: utf-8 -*-
require File.expand_path('../lib/carrierwave-qiniu/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Marble Wu"]
  gem.email         = ["huobazi@gmail.com"]
  gem.description   = %q{Qiniu Storage support for CarrierWave}
  gem.summary       = %q{Qiniu Storage support for CarrierWave}
  gem.homepage      = "https://github.com/huobazi/carrierwave-qiniu"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "carrierwave-qiniu"
  gem.require_paths = ["lib"]
  gem.version       = Carrierwave::Qiniu::VERSION


  gem.add_dependency "carrierwave" , "~> 1.0"
  gem.add_dependency "qiniu", "~> 6.8", ">= 6.8.0"
end
