require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "eu_central_bank"
    gem.summary = %Q{Calculates exchange rates based on rates from european central bank. Money gem compatible. }
    gem.description = %Q{This gem reads exchange rates from the european central bank website. It uses it to calculates exchange rates. It is compatible with the money gem}
    gem.email = "zan@liangzan.net"
    gem.homepage = "http://github.com/liangzan/eu_central_bank"
    gem.authors = ["Wong Liang Zan", "Shane Emmons"]
    gem.add_development_dependency "rspec", ">= 1.3.0"
    gem.add_development_dependency "rr", ">= 0.10.11"
    gem.add_development_dependency "shoulda", ">= 2.10.3"
    gem.add_dependency "nokogiri", ">= 1.4.1"
    gem.add_dependency "money", ">= 3.1.0.pre1"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "eu_central_bank #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
