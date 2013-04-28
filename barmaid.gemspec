# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barmaid/version'

Gem::Specification.new do |spec|
  spec.name          = "barmaid"
  spec.version       = Barmaid::VERSION
  spec.authors       = ["Holger Amann"]
  spec.email         = ["holger@sauspiel.de"]
  spec.description   = %q{restful HTTP api for 2ndQuadrant's PostgreSQL backup tool 'barman'}
  spec.summary       = %q{restful HTTP api for 2ndQuadrant's PostgreSQL backup tool 'barman'}
  spec.homepage      = "https://github.com/sauspiel/barmaid"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*', 'LICENSE.txt', 'README.md']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 1.3"
  spec.add_dependency "rbarman", "~> 0.0.7"
  spec.add_dependency "grape", "~> 0.4.1"
  spec.add_dependency "representable", "~> 1.4.0"
  spec.add_dependency "resque", "~> 1.23.1"
  spec.add_dependency "resque-status"
  spec.add_dependency "log4r"
  spec.add_dependency "mixlib-shellout", "~> 1.1.0"
  spec.add_dependency "net-ssh"
  spec.add_dependency "unicorn"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.13.0"
  spec.add_development_dependency "rack-test"
end
