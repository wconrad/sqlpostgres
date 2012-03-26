#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Select.rb
select2 = Select.new
select2.select('i')
select2.from('bar')
select1 = Select.new
select1.select('i')
select1.from('foo')
select1.union(select2)
p select1.statement    # OUTPUT
# End example
