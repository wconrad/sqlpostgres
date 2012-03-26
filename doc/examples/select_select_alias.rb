#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib/"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'sqlpostgres'
require 'Assert'

include Assert
include SqlPostgres

Connection.open do |connection|

  connection.exec("create temporary table foo (i int)")

  insert = Insert.new('foo', connection)
  insert.insert('i', 1)
  insert.exec

  # Example: ../../lib/sqlpostgres/Select.rb
  select = Select.new(connection)
  select.select('i', 'number')
  select.from('foo')
  p select.statement       # OUTPUT
  p select.exec            # OUTPUT
  # End example

  assertEquals(select.exec, [{"number"=>1}])

end
