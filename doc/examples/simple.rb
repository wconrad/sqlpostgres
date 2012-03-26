#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib/"))

# Example: ../../lib/sqlpostgres.rb
require "sqlpostgres"

include SqlPostgres

Connection.open do |connection|
  connection.exec("create temporary table foo (t text)")
  
  insert = Insert.new('foo', connection)
  insert.insert('t', 'Smith')
  insert.exec
  
  insert = Insert.new('foo', connection)
  insert.insert('t', 'Jones')
  insert.exec
  
  update = Update.new('foo', connection)
  update.set('t', "O'Brien")
  update.where(["t = %s", "Smith"])
  update.exec  
  
  select = Select.new(connection)
  select.select('t')
  select.from('foo')
  select.order_by('t')
  p select.exec  # OUTPUT
  
end
# End example

