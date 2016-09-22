# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'open_api_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "open_api_parser"
  spec.version       = OpenApiParser::VERSION
  spec.authors       = ["Braintree"]
  spec.email         = ["code@getbraintree.com"]

  spec.summary       = %q{A parser for Open API specifications}
  spec.description   = %q{A parser for Open API specifications}
  spec.homepage      = "https://github.com/braintree/open_api_parser"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "json_schema", "~> 0.13.3"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
