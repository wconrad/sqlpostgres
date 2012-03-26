#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'

require 'MockPGconn'

class TransactionTest < Test

  include SqlPostgres
  include TestUtil

  def testSuccess
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Transaction.new(connection) do
        connection.exec("foo")
        assertEquals(MockPGconn.state[:statements], 
                     ["begin transaction", "foo"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "end transaction"])
    end
  end

  def testManualCommit
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Transaction.new(connection) do
        connection.exec("foo")
        assertEquals(MockPGconn.state[:statements], 
                     ["begin transaction", "foo"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "end transaction"])
    end
  end

  def testSuccess_Real
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      Transaction.new(connection) do
        connection.exec("insert into #{table1} values (1)")
      end
      assertEquals(connection.query("select i from #{table1}"), [["1"]])
    end
  end

  def testSuccess_Real_DefaultConnection
    makeTestConnection do |connection|
      setDefaultConnection(connection) do
        connection.exec("create temporary table #{table1} (i int)")
        Transaction.new do
          connection.exec("insert into #{table1} values (1)")
        end
        assertEquals(connection.query("select i from #{table1}"), 
                     [["1"]])
      end
    end
  end

  def testRuntimeError
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      assertException(RuntimeError, "Oh no!") do
        Transaction.new(connection) do
          connection.exec("foo")
          assertEquals(MockPGconn.state[:statements], 
                       ["begin transaction", "foo"])
          raise "Oh no!"
        end
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "abort transaction"])
    end
  end

  class Sorry < Exception
  end

  def testException
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      assertException(Sorry, "Oh no!") do
        Transaction.new(connection) do
          connection.exec("foo")
          assertEquals(MockPGconn.state[:statements], 
                       ["begin transaction", "foo"])
          raise Sorry, "Oh no!"
        end
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "abort transaction"])
    end
  end

  def testException
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      assertException(Sorry, "Oh no!") do
        Transaction.new(connection) do
          connection.exec("foo")
          assertEquals(MockPGconn.state[:statements], 
                       ["begin transaction", "foo"])
          raise Sorry, "Oh no!"
        end
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "abort transaction"])
    end
  end

  def testRuntimeError_Real
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      assertException(RuntimeError, "Oh no!") do
        Transaction.new(connection) do
          connection.exec("insert into #{table1} values (1)")
          assertEquals(connection.query("select i from #{table1}"),
                       [["1"]])
          raise "Oh no!"
        end
      end
      assertEquals(connection.query("select i from #{table1}"), [])
    end
  end

  def testManualCommit
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Transaction.new(connection) do |transaction|
        connection.exec("foo")
        transaction.commit
        assertEquals(MockPGconn.state[:statements], 
                     ["begin transaction", "foo", "end transaction"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "end transaction"])
    end
  end

  def testManualCommitTwice
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Transaction.new(connection) do |transaction|
        connection.exec("foo")
        transaction.commit
        transaction.commit
        assertEquals(MockPGconn.state[:statements], 
                     ["begin transaction", "foo", "end transaction"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "end transaction"])
    end
  end

  def testManualAbortAfterCommit
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Transaction.new(connection) do |transaction|
        connection.exec("foo")
        transaction.commit
        transaction.abort
        assertEquals(MockPGconn.state[:statements], 
                     ["begin transaction", "foo", "end transaction"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "end transaction"])
    end
  end

  def testManualCommitWithException
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      begin
        Transaction.new(connection) do |transaction|
          connection.exec("foo")
          transaction.commit
          assertEquals(MockPGconn.state[:statements], 
                       ["begin transaction", "foo", "end transaction"])
          raise Sorry
        end
      rescue Sorry => e
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "end transaction"])
    end
  end

  def testManualAbort
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Transaction.new(connection) do |transaction|
        connection.exec("foo")
        transaction.abort
        assertEquals(MockPGconn.state[:statements], 
                     ["begin transaction", "foo", "abort transaction"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "abort transaction"])
    end
  end

  def testManualAbortTwice
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Transaction.new(connection) do |transaction|
        connection.exec("foo")
        transaction.abort
        transaction.abort
        assertEquals(MockPGconn.state[:statements], 
                     ["begin transaction", "foo", "abort transaction"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "abort transaction"])
    end
  end

  def testManualCommitAfterAbort
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      Transaction.new(connection) do |transaction|
        connection.exec("foo")
        transaction.abort
        transaction.commit
        assertEquals(MockPGconn.state[:statements], 
                     ["begin transaction", "foo", "abort transaction"])
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "abort transaction"])
    end
  end

  def testManualAbortWithException
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:statements], nil)
      begin
        Transaction.new(connection) do |transaction|
          connection.exec("foo")
          transaction.abort
          assertEquals(MockPGconn.state[:statements], 
                       ["begin transaction", "foo", "abort transaction"])
          raise Sorry
        end
      rescue Sorry => e
      end
      assertEquals(MockPGconn.state[:statements], 
                   ["begin transaction", "foo", "abort transaction"])
    end
  end

end

TransactionTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
