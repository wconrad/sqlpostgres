#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib/"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'sqlpostgres'
require 'Assert'

include Assert
include SqlPostgres

Connection.open do |connection|

  connection.exec("create temporary table circles (d real)")

  insert = Insert.new('circles', connection)
  insert.insert('d', 2)
  insert.exec

  # Example: ../../lib/sqlpostgres/Select.rb
  pi = 3.14
  select = Select.new(connection)
  select.select(['d * %s', pi], 'c')
  select.from('circles')
  p select.statement       # OUTPUT
  p select.exec            # OUTPUT
  # End example

  assertEquals(select.exec, [{'c'=>6.28}])

end
