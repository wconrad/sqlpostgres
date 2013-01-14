# encoding: utf-8

require 'rubygems'

require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

require File.expand_path('spec/lib/target_database_servers',
                         File.dirname(__FILE__))

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see
  #  http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = 'sqlpostgres'
  gem.homepage = 'http://github.com/wconrad/sqlpostgres'
  gem.license = 'MIT'
  gem.summary = %Q{library for postgresql queries}
  gem.description =
    ('A mini-language for building and executing SQL statements '\
     'against a postgresql database.  This is a very old library, '\
     'pre-dating active record and lacking many of its refinments.  '\
     'New projects will probably not want to use it.')
  gem.email = 'wconrad@yagni.com'
  gem.authors = ['Wayne Conrad']
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

desc "Run Tests"
task :test do
  system 'test/test'
end

namespace 'db' do

  def target_database_servers
    TestSupport::TargetDatabaseServers.instance
  end

  desc 'Create test databases'
  task 'create' do
    target_database_servers.create_databases
  end

  desc 'Drop test databases'
  task 'drop' do
    target_database_servers.drop_databases
  end

end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :spec => ['db:create'] do
end

task :default => :spec

# Local Variables:
# mode: ruby
# End:
