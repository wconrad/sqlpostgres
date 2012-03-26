#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))
require '../tools/exampleinserter/ExampleInserter'

for example in Dir['examples/*.rb']
  puts "----- #{example}"
  ExampleInserter.new(example).run
end
