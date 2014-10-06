#!/bin/env ruby
# encoding: utf-8
Gem::Specification.new do |s|
  s.name         = "eu_central_bank"
  s.version      = "0.3.8"
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Wong Liang Zan", "Shane Emmons", "Thorsten Böttger", "Jonathan Eisenstein"]
  s.email        = ["zan@liangzan.net"]
  s.homepage     = "http://github.com/RubyMoney/eu_central_bank"
  s.summary      = "Calculates exchange rates based on rates from european central bank. Money gem compatible."
  s.description  = "This gem reads exchange rates from the european central bank website. It uses it to calculates exchange rates. It is compatible with the money gem"

  s.add_dependency "nokogiri"
  s.add_dependency "money", "~> 6.3.0"

  s.add_development_dependency "rspec", "~> 3.0.0"

  s.files         = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md)
  s.require_path = "lib"
end
