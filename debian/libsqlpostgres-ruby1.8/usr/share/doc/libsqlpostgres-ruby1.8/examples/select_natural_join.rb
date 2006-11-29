#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Select.rb
select = Select.new
select.select('i')
select.from('foo')
select.natural_join('bar')
p select.statement        # OUTPUT
# End example
