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
