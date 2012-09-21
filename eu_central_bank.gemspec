Gem::Specification.new do |s|
  s.name         = "eu_central_bank"
  s.version      = "0.3.2"
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Wong Liang Zan", "Shane Emmons", "Thorsten Böttger", "Jonathan Eisenstein"]
  s.email        = ["zan@liangzan.net"]
  s.homepage     = "http://github.com/RubyMoney/eu_central_bank"
  s.summary      = "Calculates exchange rates based on rates from european central bank. Money gem compatible."
  s.description  = "This gem reads exchange rates from the european central bank website. It uses it to calculates exchange rates. It is compatible with the money gem, This fork of the gem saves cache data to redis isntead of a file"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "nokogiri"
  s.add_dependency "money",    ">= 5.0.0"
  s.add_dependency "redis",    "~> 3.0.1"

  s.add_development_dependency "rspec", ">= 2.0.0"
  s.add_development_dependency "rr"
  s.add_development_dependency "shoulda"

  s.files         = Dir.glob("lib/**/*") + %w(CHANGELOG.rdoc LICENSE README.rdoc)
  s.require_path = "lib"
end

