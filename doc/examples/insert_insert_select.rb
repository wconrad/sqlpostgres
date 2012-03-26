#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Insert.rb
select = Select.new
select.select('j')
select.from('bar')
select.limit(1)
insert = Insert.new('foo')
insert.insert('i', select)
p insert.statement           # OUTPUT
# End example
