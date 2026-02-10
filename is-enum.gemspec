# frozen_string_literal: true

require_relative 'lib/is-enum/info'

Gem::Specification::new do |s|
  s.name     =   IS::Enum::Info::NAME
  s.version  =   IS::Enum::Info::VERSION
  s.summary  =   IS::Enum::Info::SUMMARY
  s.authors  = [ IS::Enum::Info::AUTHOR ]
  s.homepage =   IS::Enum::Info::HOMEPAGE
  s.license  =   IS::Enum::Info::LICENSE

  s.files = Dir[ 'lib/**/*', 'README.md', 'LICENSE', 'coverage-badge.svg' ]

  s.required_ruby_version = "~> 3.4"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "yard"
  s.add_development_dependency "redcarpet"
  s.add_development_dependency 'rdoc'
end
