#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'

require 'MockPGconn'

class SavepointTest < Test

  include SqlPostgres
  include TestUtil

  def testSuccess
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Savepoint.new('bar', connection) do
        connection.exec("foo")
        assertEquals(MockPGconn.state[:statements], 
                     ["savepoint bar", "foo"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "release savepoint bar"])
    end
  end

  def testManualCommit
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Savepoint.new('bar', connection) do
        connection.exec("foo")
        assertEquals(MockPGconn.state[:statements], 
                     ["savepoint bar", "foo"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "release savepoint bar"])
    end
  end

  def testSuccess_Real
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      Transaction.new(connection) do
        connection.exec("insert into #{table1} values (1)")
        Savepoint.new('bar', connection) do
          connection.exec("insert into #{table1} values (2)")
        end
        connection.exec("insert into #{table1} values (3)")
      end
      assertEquals(connection.query("select i from #{table1} order by i"), [["1"], ["2"], ["3"]])
    end
  end

  def testSuccess_Real_DefaultConnection
    makeTestConnection do |connection|
      setDefaultConnection(connection) do
        connection.exec("create temporary table #{table1} (i int)")
        Transaction.new(connection) do
          connection.exec("insert into #{table1} values (1)")
          Savepoint.new('bar') do
            connection.exec("insert into #{table1} values (2)")
          end
          connection.exec("insert into #{table1} values (3)")
        end
        assertEquals(connection.query("select i from #{table1} order by i"), [["1"], ["2"], ["3"]])
      end
    end
  end

  def testRuntimeError
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      assertException(RuntimeError, "Oh no!") do
        Savepoint.new('bar', connection) do
          connection.exec("foo")
          assertEquals(MockPGconn.state[:statements], 
                       ["savepoint bar", "foo"])
          raise "Oh no!"
        end
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
    end
  end

  class Sorry < Exception
  end

  def testException
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      assertException(Sorry, "Oh no!") do
        Savepoint.new('bar', connection) do
          connection.exec("foo")
          assertEquals(MockPGconn.state[:statements], 
                       ["savepoint bar", "foo"])
          raise Sorry, "Oh no!"
        end
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
    end
  end

  def testException
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      assertException(Sorry, "Oh no!") do
        Savepoint.new('bar', connection) do
          connection.exec("foo")
          assertEquals(MockPGconn.state[:statements], 
                       ["savepoint bar", "foo"])
          raise Sorry, "Oh no!"
        end
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
    end
  end

  def testRuntimeError_Real
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      Transaction.new(connection) do
        connection.exec("insert into #{table1} values (1)")
        assertException(RuntimeError, "Oh no!") do
          Savepoint.new('bar', connection) do
            connection.exec("insert into #{table1} values (2)")
            assertEquals(connection.query("select i from #{table1}"),
                         [["1"], ["2"]])
            raise "Oh no!"
          end
        end
        connection.exec("insert into #{table1} values (3)")
      end
      assertEquals(connection.query("select i from #{table1} order by i"), [["1"], ["3"]])
    end
  end

  def testManualCommit
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Savepoint.new('bar', connection) do |transaction|
        connection.exec("foo")
        transaction.commit
        assertEquals(MockPGconn.state[:statements], 
                     ["savepoint bar", "foo", "release savepoint bar"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "release savepoint bar"])
    end
  end

  def testManualCommitTwice
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Savepoint.new('bar', connection) do |transaction|
        connection.exec("foo")
        transaction.commit
        transaction.commit
        assertEquals(MockPGconn.state[:statements], 
                     ["savepoint bar", "foo", "release savepoint bar"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "release savepoint bar"])
    end
  end

  def testManualAbortAfterCommit
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Savepoint.new('bar', connection) do |transaction|
        connection.exec("foo")
        transaction.commit
        transaction.abort
        assertEquals(MockPGconn.state[:statements], 
                     ["savepoint bar", "foo", "release savepoint bar"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "release savepoint bar"])
    end
  end

  def testManualCommitWithException
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      begin
        Savepoint.new('bar', connection) do |transaction|
          connection.exec("foo")
          transaction.commit
          assertEquals(MockPGconn.state[:statements], 
                       ["savepoint bar", "foo", "release savepoint bar"])
          raise Sorry
        end
      rescue Sorry => e
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "release savepoint bar"])
    end
  end

  def testManualAbort
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Savepoint.new('bar', connection) do |transaction|
        connection.exec("foo")
        transaction.abort
        assertEquals(MockPGconn.state[:statements], 
                     ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
    end
  end

  def testManualAbortTwice
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Savepoint.new('bar', connection) do |transaction|
        connection.exec("foo")
        transaction.abort
        transaction.abort
        assertEquals(MockPGconn.state[:statements], 
                     ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
    end
  end

  def testManualCommitAfterAbort
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Savepoint.new('bar', connection) do |transaction|
        connection.exec("foo")
        transaction.abort
        transaction.commit
        assertEquals(MockPGconn.state[:statements], 
                     ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
    end
  end

  def testManualAbortWithException
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      begin
        Savepoint.new('bar', connection) do |transaction|
          connection.exec("foo")
          transaction.abort
          assertEquals(MockPGconn.state[:statements], 
                       ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
          raise Sorry
        end
      rescue Sorry => e
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["savepoint bar", "foo", "rollback to bar", "release savepoint bar"])
    end
  end

end

SavepointTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
