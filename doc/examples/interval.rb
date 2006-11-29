#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../test"))
$:.unshift(File.join(File.dirname(__FILE__), "../../lib/"))

require 'Assert'
require 'sqlpostgres'

include Assert
include SqlPostgres

# Example: ../../lib/sqlpostgres/PgInterval.rb
interval = PgInterval.new('hours'=>1, 'minutes'=>30)
p interval.hours                                      # OUTPUT
p interval.minutes                                    # OUTPUT
p interval.seconds                                    # OUTPUT
# End example
