#!/usr/bin/ruby1.8

$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))
$:.unshift(File.join(File.dirname(__FILE__), "../../test"))

require 'Assert'
require 'sqlpostgres'

include SqlPostgres
include Assert

# Example: ../../lib/sqlpostgres/Translate.rb
p Translate.substitute_values(['foo'])                 # OUTPUT
p Translate.substitute_values(['%s + %s', 1, 2])       # OUTPUT
p Translate.substitute_values([:in, 1, 2])             # OUTPUT
p Translate.substitute_values([:in, 'foo', 'bar'])     # OUTPUT
# End example
