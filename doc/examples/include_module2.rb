#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "../../lib/")

# Example: ../manual.dbk
require 'sqlpostgres'
include SqlPostgres

Connection.open do |connection|
  #...
end
# End example
