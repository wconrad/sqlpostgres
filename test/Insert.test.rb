#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'

# Much of Insert is tested in the "roundtrip" test.

class InsertTest < Test

  include SqlPostgres
  include TestUtil

  def testInsert_Subselect
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      select = Select.new
      select.select_literal(1)
      insert = Insert.new(table1, connection)
      insert.insert('i', select)
      ret = insert.exec
      assertEquals(connection.query("select i from #{table1}"),
                   [["1"]])
    end
  end

  def testInsert_Expression
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      insert = Insert.new(table1, connection)
      insert.insert('i', ['1 + 1'])
      assertEquals(insert.statement, 
                   "insert into #{table1} (i) values (1 + 1)")
      insert.exec
      assertEquals(connection.query("select i from #{table1}"),
                   [["2"]])
    end
  end

  def testSelect
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      select = Select.new
      select.select_literal(1)
      insert = Insert.new(table1, connection)
      insert.insert('i')
      insert.select(select)
      insert.exec
      assertEquals(connection.query("select i from #{table1}"), [["1"]])
    end
  end

  def testDefaultConnection
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      setDefaultConnection(connection) do
        insert = Insert.new(table1)
        insert.insert('i', 1)
        insert.exec
        assertEquals(connection.query("select i from #{table1}"), 
                     [["1"]])
      end
    end
  end

  def testGiveConnectionToExec
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      insert = Insert.new(table1)
      insert.insert('i', 1)
      insert.exec(connection)
      assertEquals(connection.query("select i from #{table1}"), 
                   [["1"]])
    end
  end

  def testInsertDefaultValues
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int default 0)")
      insert = Insert.new(table1, connection)
      insert.default_values
      insert.exec
      assertEquals(connection.query("select i from #{table1}"),
                   [["0"]])
    end
  end

  def testInsertDefault
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int default 0)")
      insert = Insert.new(table1, connection)
      insert.insert('i', :default)
      insert.exec
      assertEquals(connection.query("select i from #{table1}"),
                   [["0"]])
    end
  end

  def testInsertReturning
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      insert = Insert.new(table1, connection)
      insert.insert('i', 2)
      insert.returning('i * 3', 'calc')
      assertEquals(insert.statement, 
                   "insert into #{table1} (i) values (2) returning i * 3 as calc")
      ret = insert.exec
      assertEquals(connection.query("select i from #{table1}"),
                   [["2"]])
      assertEquals(ret.result, [["6"]])
    end
  end

end

InsertTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
