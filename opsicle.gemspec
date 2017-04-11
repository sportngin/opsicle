# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opsicle/version'

Gem::Specification.new do |spec|
  spec.name          = "opsicle"
  spec.version       = Opsicle::VERSION
  spec.authors       = ["Andy Fleener", "Nick LaMuro"]
  spec.email         = ["andrew.fleener@sportngin.com"]
  spec.description   = %q{CLI for the opsworks platform}
  spec.summary       = %q{An opsworks specific abstraction on top of the aws sdk}
  spec.homepage      = "https://github.com/sportngin/opsicle"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*', 'bin/*', 'LICENSE', 'README.md']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir['spec/**/*']
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", "~> 2"
  spec.add_dependency "gli", "~> 2.9"
  spec.add_dependency "highline", "~> 1.6"
  spec.add_dependency "terminal-table", "~> 1.4"
  spec.add_dependency "minitar", "~> 0.6"
  spec.add_dependency "hashdiff", "~> 0.2"
  spec.add_dependency "curses", "~> 1.0.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "rspec", "~> 3.0.0.beta2"
  spec.add_development_dependency "guard", "~> 2.5.0"
  spec.add_development_dependency "guard-rspec", "~> 4.2"
end
