#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Select.rb
select = Select.new
select.select('i')
select.select('count(*)', 'count')
select.from('foo')
select.group_by('i')
select.having('i < 10')
p select.statement       # OUTPUT
# End example
