#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Insert.rb
insert = Insert.new('foo')
insert.insert_bytea('t', "\000\001\002\003")
p insert.statement     # OUTPUT
# End example
