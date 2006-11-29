#!/usr/bin/ruby1.8

$:.unshift File.join(File.dirname(__FILE__), "../../lib/")

require 'sqlpostgres'
include SqlPostgres

# Example: ../manual.dbk
Connection.open do |connection|
  Connection.default = connection
  select = Select.new
  select.select_literal(1, 'i')    # OUTPUT
  p select.exec
end
# End example
