#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Select.rb
subselect = Select.new
subselect.select('i')
subselect.from('foo')
select = Select.new
select.select('i')
select.from(subselect, 'bar')
p select.statement  # OUTPUT
# End example
