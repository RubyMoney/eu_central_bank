#!/bin/env ruby
# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name         = "eu_central_bank"
  s.version      = "2.0.0"
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Shane Emmons"]
  s.email        = ["shane@emmons.io"]
  s.homepage     = "https://github.com/RubyMoney/eu_central_bank"
  s.summary      = "Calculates exchange rates based on rates from european central bank. Money gem compatible."
  s.description  = "This gem reads exchange rates from the european central bank website. It uses it to calculates exchange rates. It is compatible with the money gem"
  s.license      = "MIT"

  s.metadata['changelog_uri'] = "https://github.com/RubyMoney/eu_central_bank/blob/main/CHANGELOG.md"
  s.metadata['source_code_uri'] = "https://github.com/RubyMoney/eu_central_bank"
  s.metadata['bug_tracker_uri'] = "https://github.com/RubyMoney/eu_central_bank/issues"

  s.required_ruby_version = ">= 3.1.0"

  s.add_dependency "bigdecimal"
  s.add_dependency "nokogiri", "~> 1.11"
  s.add_dependency "money", "~> 7.0"

  s.add_development_dependency "rspec", "~> 3.13"

  s.files         = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md)
  s.require_path = "lib"
end
