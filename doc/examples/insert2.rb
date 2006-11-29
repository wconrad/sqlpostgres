#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

Connection.open do |connection|

  connection.exec("create temporary table person (name text, "\
                  "date_of_birth date)")

  # Example: ../manual.dbk
  insert = Insert.new('person', connection)
  insert.insert('name', "O'Reilly")
  insert.insert('date_of_birth', Date.civil(1972, 1, 1))
  p insert.statement         # OUTPUT
  insert.exec
  # End example

  select = Select.new(connection)
  select.select('name')
  select.select('date_of_birth')
  select.from('person')
  assertEquals(select.exec, [
                 {
                   'name'=>"O'Reilly", 
                   'date_of_birth'=>Date.civil(1972, 1, 1)
                 }
               ])

end
