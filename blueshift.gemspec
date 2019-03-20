# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blueshift/version'

Gem::Specification.new do |spec|
  spec.name          = 'blue-shift'
  spec.version       = Blueshift::VERSION
  spec.authors       = ['Gabriel Mansour']
  spec.email         = ['dev+gabriel@influitive.com']

  spec.description   = %q{Amazon Redshift adapter for Sequel}
  spec.summary       = %q{Amazon Redshift adapter for Sequel}
  spec.homepage      = 'https://github.com/influitive/blueshift'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sequel'
  spec.add_dependency 'pg'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'dotenv'
end
