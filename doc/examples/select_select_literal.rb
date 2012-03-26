#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

Connection.open do |connection|

  # Example: ../../lib/sqlpostgres/Select.rb
  select = Select.new(connection)
  select.select_literal(2, 'n')
  select.select_literal('foo', 't')
  p select.statement         # OUTPUT
  p select.exec              # OUTPUT
  # End example

  assertEquals(select.exec, [{'n'=>2, 't'=>'foo'}])

end
