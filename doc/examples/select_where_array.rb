#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Select.rb
select = Select.new
select.select('age')
select.from('person')
select.where(['name = %s', 'Smith'])
p select.statement     # OUTPUT
# End example
