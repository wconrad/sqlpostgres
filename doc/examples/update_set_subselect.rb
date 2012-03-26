#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Update.rb
select = Select.new
select.select('j')
select.from('bar')
select.where(["i = foo.i"])
update = Update.new('foo')
update.set('i', select)
p update.statement         # OUTPUT
# End example
