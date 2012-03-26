#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

Connection.open do |connection|

  connection.exec("create temporary table foo (i int)")

  # Example: ../../lib/sqlpostgres/Transaction.rb
  Transaction.new(connection) do

    insert = Insert.new('foo', connection)
    insert.insert('i', 1)
    insert.exec

    insert = Insert.new('foo', connection)
    insert.insert('i', 2)
    insert.exec

  end
  # End example

end
