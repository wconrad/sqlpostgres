#!/usr/bin/ruby1.8

$:.unshift File.join(File.dirname(__FILE__), "../../lib/")

require 'sqlpostgres'
include SqlPostgres

Connection.open do |connection|

  connection.exec("create temporary table person (name text)")

  # Example: ../manual.dbk
  insert = Insert.new('person')
  insert.insert('name', 'Fred')
  insert.exec(connection)
  # End example

end
