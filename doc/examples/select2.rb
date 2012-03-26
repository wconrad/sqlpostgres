#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

Connection.open do |connection|

  connection.exec("create temporary table person (name text, married boolean)")

  insert = Insert.new('person', connection)
  insert.insert('name', 'Fred')
  insert.insert('married', false)
  insert.exec

  insert = Insert.new('person', connection)
  insert.insert('name', 'Mary')
  insert.insert('married', false)
  insert.exec

  # Example: ../manual.dbk
  select = Select.new(connection)
  select.select('name')
  select.select('married')
  select.from('person')
  select.where(['married = %s', false])
  p select.statement    # OUTPUT
  p select.exec         # OUTPUT
  # End example

end
