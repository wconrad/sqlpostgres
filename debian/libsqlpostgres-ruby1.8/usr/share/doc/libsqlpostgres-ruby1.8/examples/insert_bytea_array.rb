#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Insert.rb
insert = Insert.new('foo')
insert.insert_bytea_array('t', ["foo", "\000bar\nbaz"])
p insert.statement     # OUTPUT

# End example
