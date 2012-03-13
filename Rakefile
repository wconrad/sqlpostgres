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
