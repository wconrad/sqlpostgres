#!/usr/bin/ruby1.8

$:.unshift File.join(File.dirname(__FILE__), "../../lib/")

require 'sqlpostgres'
include SqlPostgres

# Example: ../manual.dbk
pgconn = PGconn.connect('localhost', 5432, '', '', ENV['USER'])
connection = Connection.new('connection'=>pgconn)
# use the connection
connection.close    # or, if you prefer, pgconn.close
# End example
