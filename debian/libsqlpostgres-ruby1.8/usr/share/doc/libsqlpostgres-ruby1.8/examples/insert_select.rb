#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Insert.rb
select = Select.new
select.select('i')
select.from('bar')
insert = Insert.new('foo')
insert.insert('i')
insert.select(select)
p insert.statement     # OUTPUT
# End example
