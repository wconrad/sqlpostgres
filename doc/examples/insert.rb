#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

Connection.open do |connection|

  connection.exec("create temporary table foo (i int, t text)")

  # Example: ../../lib/sqlpostgres/Insert.rb
  insert = Insert.new('foo', connection)
  insert.insert('i', 1)
  insert.insert('t', 'foo')
  p insert.statement           # OUTPUT
  insert.exec
  # End example

  select = Select.new(connection)
  select.select('i')
  select.select('t')
  select.from('foo')
  assertEquals(select.exec, [{'i'=>1, 't'=>'foo'}])

end
