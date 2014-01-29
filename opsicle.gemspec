# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opsicle/version'

Gem::Specification.new do |spec|
  spec.name          = "opsicle"
  spec.version       = Opsicle::VERSION
  spec.authors       = ["Andy Fleener"]
  spec.email         = ["andrew.fleener@sportngin.com"]
  spec.description   = %q{CLI for the opsworks platform}
  spec.summary       = %q{An opsworks specific abstraction on top of the aws sdk}
  spec.homepage      = "https://github.com/sportngin/opsicle"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", "~> 1.30"
  spec.add_dependency "commander"
  spec.add_dependency "terminal-table"
  spec.add_dependency "rugged"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
end
