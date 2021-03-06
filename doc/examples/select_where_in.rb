#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Select.rb
select = Select.new
select.select('s')
select.from('foo')
select.where(['s in %s', [:in, 'foo', 'bar']])
p select.statement     # OUTPUT
# End example
