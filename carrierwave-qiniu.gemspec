require_relative 'lib/carrierwave/qiniu/version'

Gem::Specification.new do |spec|
  spec.name          = "carrierwave-qiniu"
  spec.version       = Carrierwave::Qiniu::VERSION
  spec.authors       = ["Marble Wu"]
  spec.email         = ["huobazi@gmail.com"]

  spec.summary       = %q{Qiniu Storage support for CarrierWave}
  spec.description   = %q{Qiniu Storage support for CarrierWave}
  spec.homepage      = "https://github.com/huobazi/carrierwave-qiniu"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/huobazi/carrierwave-qiniu"
  spec.metadata["changelog_uri"] = "https://github.com/huobazi/carrierwave-qiniu/blob/master/CHANGELOG.md.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]


  spec.add_dependency "carrierwave" , ">= 1"
  spec.add_dependency "qiniu", "~> 6.9", ">= 6.9.0"
end
