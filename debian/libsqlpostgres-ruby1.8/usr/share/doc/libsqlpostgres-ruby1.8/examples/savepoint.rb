#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

Connection.open do |connection|

  connection.exec("create temporary table foo (i int)")

  # Example: ../../lib/sqlpostgres/Savepoint.rb
  Transaction.new(connection) do

    insert = Insert.new('foo', connection)
    insert.insert('i', 1)
    insert.exec

    Savepoint.new('bar', connection) do |sp|
      insert = Insert.new('foo', connection)
      insert.insert('i', 2)
      sp.abort
    end

    insert = Insert.new('foo', connection)
    insert.insert('i', 3)
    insert.exec

  end

  p connection.query("select i from foo order by i") #OUTPUT
  # End example

end
