#!/bin/env ruby
# encoding: utf-8
Gem::Specification.new do |s|
  s.name         = "eu_central_bank"
  s.version      = "1.1.0"
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Shane Emmons"]
  s.email        = ["shane@emmons.io"]
  s.homepage     = "https://github.com/RubyMoney/eu_central_bank"
  s.summary      = "Calculates exchange rates based on rates from european central bank. Money gem compatible."
  s.description  = "This gem reads exchange rates from the european central bank website. It uses it to calculates exchange rates. It is compatible with the money gem"

  if RUBY_VERSION < '2.1'
    s.add_dependency "nokogiri", "~> 1.6.3"
  else
    s.add_dependency "nokogiri", "~> 1.7.0"
  end
  s.add_dependency "money", "~> 6.8.0"

  s.add_development_dependency "rspec", "~> 3.5.0"

  s.files         = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md)
  s.require_path = "lib"
end
