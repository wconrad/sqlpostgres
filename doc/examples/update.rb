#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

Connection.open do |connection|

  connection.exec("create temporary table foo (i integer)")

  insert = Insert.new('foo', connection)
  insert.insert('i', 1)
  insert.exec

  # Example: ../../lib/sqlpostgres/Update.rb
  update = Update.new('foo', connection)
  update.set('i', 2)
  p update.statement    # OUTPUT
  update.exec
  # End example

  select = Select.new(connection)
  select.select('i')
  select.from('foo')
  assertEquals(select.exec, [{'i'=>2}])

end
