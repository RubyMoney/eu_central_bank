require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

def gemspec
  @gemspec ||= begin
    file = File.expand_path("../eu_central_bank.gemspec", __FILE__)
    eval(File.read(file), binding, file)
  end
end

RSpec::Core::RakeTask.new
task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new

begin
  require 'rubygems/package_task'
  Gem::PackageTask.new(gemspec) do |pkg|
    pkg.gem_spec = gemspec
  end
  task :gem => :gemspec
rescue LoadError
  task(:gem){abort "`gem install rake` to package gems"}
end

desc "Install the gem locally"
task :install => :gem do
  sh "gem install pkg/#{gemspec.full_name}.gem"
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end
