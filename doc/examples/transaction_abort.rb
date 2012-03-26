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
  Transaction.new(connection) do |transaction|
    insert = Insert.new('foo', connection)
    insert.insert('i', 1)
    insert.exec
    transaction.abort
  end

  select = Select.new(connection)
  select.select('i')
  select.from('foo')
  p select.exec            # OUTPUT
  # End example

end
