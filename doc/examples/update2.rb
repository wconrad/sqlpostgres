#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

Connection.open do |connection|

  connection.exec("create temporary table person (name text, married boolean)")

  insert = Insert.new('person', connection)
  insert.insert('name', 'Jones')
  insert.insert('married', false)
  insert.exec

  insert = Insert.new('person', connection)
  insert.insert('name', 'Smith')
  insert.insert('married', false)
  insert.exec

  # Example: ../manual.dbk
  update = Update.new('person', connection)
  update.set('married', true)
  update.where(['name = %s', 'Smith'])
  p update.statement                # OUTPUT
  update.exec
  # End example

  select = Select.new(connection)
  select.select('name')
  select.select('married')
  select.from('person')
  select.order_by('name')
  assertEquals(select.exec, [
                 {'name'=>'Jones', 'married'=>false},
                 {'name'=>'Smith', 'married'=>true},
               ])

end
