#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Update.rb
update = Update.new('foo')
update.set('i', 1)
update.where(['t = %s', "bar"])
p update.statement     # OUTPUT
# End example
