# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barmaid/version'

Gem::Specification.new do |spec|
  spec.name          = "barmaid"
  spec.version       = Barmaid::VERSION
  spec.authors       = ["Holger Amann"]
  spec.email         = ["holger@sauspiel.de"]
  spec.description   = %q{Web Application for providing an API for 2ndQuadrant's PostgreSQL backup tool 'barman'}
  spec.summary       =  %q{Web Application for providing an API for 2ndQuadrant's PostgreSQL backup tool 'barman'}
  spec.homepage      = "https://github.com/sauspiel/barmaid"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*', 'LICENSE.txt', 'README.md']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 1.3"
  spec.add_dependency "rbarman", "~> 0.0.5"
  spec.add_dependency "sinatra", "~> 1.4.2"
  spec.add_dependency "sinatra-jsonp"
  spec.add_dependency "resque-queue-lock"
  spec.add_dependency "log4r"
  spec.add_dependency "mixlib-shellout", "~> 1.1.0"
  spec.add_dependency "resque", "~> 1.23.1"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.13.0"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "sinatra-reloader"
end
