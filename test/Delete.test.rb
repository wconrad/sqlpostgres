#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
$:.unshift(File.dirname(__FILE__))
require 'TestSetup'

# Much of Insert is tested in the "roundtrip" test.

class DeleteTest < Test

  include SqlPostgres
  include TestUtil

  def testDelete_NoWhereClause
    testit([1, 2, 3], []) do |table, connection|
      sql = Delete.new(table, connection)
      sql.exec
    end
  end

  def testDelete_OneWhereClause
    testit([1, 2, 3], [2]) do |table, connection|
      sql = Delete.new(table, connection)
      sql.where('i % 2 = 1')
      sql.exec
    end
  end

  def testDelete_TwoWhereClauses
    testit([1, 2, 3], [1, 2]) do |table, connection|
      sql = Delete.new(table, connection)
      sql.where('i % 2 = 1')
      sql.where('i > 2')
      sql.exec
    end
  end

  def testDelete_PassConnectionToExec
    testit([1, 2, 3], []) do |table, connection|
      sql = Delete.new(table)
      sql.exec(connection)
    end
  end

  def testit(initial, final)
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      for i in initial
        connection.exec("insert into #{table1} (i) values (#{i})")
      end
      yield(table1, connection)
      values = connection.query("select i from #{table1}").collect do |row|
        row[0].to_i
      end
      assertEquals(values, final)
    end
  end

end

DeleteTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
