#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "../../lib/")

require 'sqlpostgres'
include SqlPostgres

# Example: ../manual.dbk
connection = Connection.new
# use the connection
connection.close
# End example
