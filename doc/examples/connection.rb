#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../test"))
$:.unshift(File.join(File.dirname(__FILE__), "../../lib/"))

require 'Assert'
require 'sqlpostgres'

include Assert
include SqlPostgres

# Example: ../manual.dbk
Connection.open do |connection|
  # Use the connection
end
# End example
