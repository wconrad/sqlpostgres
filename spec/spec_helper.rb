require File.expand_path('../lib/sqlpostgres.rb', File.dirname(__FILE__))

[
  'support/**/*.rb',
].each do |relative_glob|
  absolute_glob = File.expand_path(relative_glob, File.dirname(__FILE__))
  Dir[absolute_glob].each do |path|
    require path
  end
end
