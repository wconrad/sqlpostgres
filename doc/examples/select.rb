#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../test"))
$:.unshift(File.join(File.dirname(__FILE__), "../../lib/"))

require 'Assert'
require 'sqlpostgres'

include Assert
include SqlPostgres

Connection.open do |connection|

  connection.exec("create temporary table foo (i int)")

  for i in [1, 2, nil]
    insert = Insert.new('foo', connection)
    insert.insert('i', i)
    insert.exec
  end

  # Example: ../../lib/sqlpostgres/Select.rb
  select = Select.new(connection)
  select.select('i')
  select.from('foo')
  select.order_by('i')
  p select.statement   # OUTPUT
  p select.exec        # OUTPUT
  # End example

  assertEquals(select.exec, [{"i"=>1}, {"i"=>2}, {"i"=>nil}])

end
