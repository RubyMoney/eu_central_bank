Gem::Specification.new do |s|
  s.name        = "eu_central_bank"
  s.version     = "0.2.3"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Wong Liang Zan", "Shane Emmons"]
  s.email       = ["zan@liangzan.net"]
  s.homepage    = "http://github.com/RubyMoney/eu_central_bank"
  s.summary     = "Calculates exchange rates based on rates from european central bank. Money gem compatible."
  s.description = "This gem reads exchange rates from the european central bank website. It uses it to calculates exchange rates. It is compatible with the money gem"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "nokogiri"
  s.add_dependency "money",    "~> 3.7.1"

  s.add_development_dependency "rspec", ">= 2.0.0"
  s.add_development_dependency "rr"
  s.add_development_dependency "shoulda"

  s.files         = Dir.glob("lib/**/*") + %w(CHANGELOG.rdoc LICENSE README.rdoc)
  s.require_path = "lib"
end

