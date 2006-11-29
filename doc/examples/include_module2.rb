#!/usr/bin/ruby1.8

$:.unshift File.join(File.dirname(__FILE__), "../../lib/")

# Example: ../manual.dbk
require 'sqlpostgres'
include SqlPostgres

Connection.open do |connection|
  #...
end
# End example
