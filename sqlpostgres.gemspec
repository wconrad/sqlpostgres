require 'rake'
Gem::Specification.new do |spec|
  spec.name = 'sqlpostgres'
  spec.version = '1.0'
  spec.date = '2012-03-13'
  spec.add_dependency('pg', '>= 0.12.0')
  spec.summary = 'sqL wrapper for the PG gem'
  spec.description = 'SQL wrapper for the PG gem'
  spec.authors = ['Wayne Conrad']
  spec.email = 'wconrad@yagni.com'
  spec.files = FileList['lib/**/*', 'doc/**/*', 'test/**/*', 'tools/**/*', 'Rakefile', 'sqlpostgres.gemspec']
  spec.homepage = 'http://www.yagni.com'
  spec.has_rdoc = true
end
