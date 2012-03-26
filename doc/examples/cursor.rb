#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

Connection.open do |connection|

  connection.exec("create temporary table foo (i int)")
  5.times do |i|
    connection.exec("insert into foo (i) values (#{i})")
  end

  # Example: ../../lib/sqlpostgres/Cursor.rb
  Transaction.new(connection) do
    select = Select.new(connection)
    select.select('i')
    select.from('foo')
    Cursor.new('my_cursor', select, {}, connection) do |cursor|
      while !(rows = cursor.fetch).empty?
        for row in rows
          p row # OUTPUT
                # OUTPUT
                # OUTPUT
                # OUTPUT
                # OUTPUT
          end
      end
    end
  end
  # End example

end
