desc "Build Gem"
task :build do
  system "gem build sqlpostgres.gemspec"
end

desc "Run Tests"
task :test do
  system 'test/test'
end

desc "Create docs"
task :docs do
  system 'doc/makerdoc'
  system `xmlto -o $(dir $@) html-nochunks $<`
end

desc "Publish gems"
task :publish do
  Rake::Task[:build].invoke
  system "scp *.gem production@isengard:/var/www/gems/gems/"
  system "ssh production@isengard 'gem generate_index -d /var/www/gems'"
end
