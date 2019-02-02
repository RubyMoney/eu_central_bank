#!/bin/env ruby
# encoding: utf-8
Gem::Specification.new do |s|
  s.name         = "eu_central_bank"
  s.version      = "1.4.2"
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Shane Emmons"]
  s.email        = ["shane@emmons.io"]
  s.homepage     = "https://github.com/RubyMoney/eu_central_bank"
  s.summary      = "Calculates exchange rates based on rates from european central bank. Money gem compatible."
  s.description  = "This gem reads exchange rates from the european central bank website. It uses it to calculates exchange rates. It is compatible with the money gem"

  s.add_dependency "nokogiri", RUBY_VERSION >= "2.1" ? "~> 1.8" : "~> 1.6.8"
  s.add_dependency "money", "~> 6.13"

  s.add_development_dependency "rspec", "~> 3.5.0"

  s.files         = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md)
  s.require_path = "lib"
end
