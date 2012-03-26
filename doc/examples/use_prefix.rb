#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "../../lib/")

# Example: ../../lib/sqlpostgres.rb
require 'sqlpostgres'
insert = SqlPostgres::Insert.new('foo')
# End example
