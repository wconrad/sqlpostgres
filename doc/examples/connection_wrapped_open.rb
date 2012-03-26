#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "../../lib/")

require 'sqlpostgres'
include SqlPostgres

# Example: ../manual.dbk
pgconn = PGconn.connect('localhost', 5432, '', '', ENV['USER'])
connection = Connection.open('connection'=>pgconn) do |connection|
  # use the connection
end
# End example
