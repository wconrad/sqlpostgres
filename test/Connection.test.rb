#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'

require 'MockPGconn'
require 'RandomThings'

class ConnectionTest < Test

  include SqlPostgres
  include RandomThings
  include TestConfig
  include TestUtil

  def test_ConnectionNewWrap
    Connection.mockPgClass do
      rawConnection = MockPGconn.new
      assertEquals(MockPGconn.state[:encoding], nil)
      connection = Connection.new('connection'=>rawConnection)
      assertEquals(rawConnection.state[:encoding], 'unicode')
    end
  end

  def test_ConnectionNewWithBlock
    assertException(ArgumentError, "Block not allowed") do
      Connection.new do |connection|
      end
    end
  end

  def testOpen_RealConnection
    s = Connection.open(testDbArgs) do |connection|
      assertEquals(connection.query("select 1;"), [["1"]])
      "foo"
    end
    assertEquals(s, "foo")
  end

  def testOpen_RealConnection_SelectDatabase
    dbName = "sqlpostgres_test1"
    Connection.open(testDbArgs) do |connection1|
      connection1.exec("create database #{dbName}")
      begin
        Connection.open('db_name'=>dbName) do |connection2|
           rows = connection2.query("select current_database();")
           assertEquals(rows[0][0], dbName)
        end
        sleep(0.1) # I don't know why, but it seems to take some time
                   # for the connection to be closed
      ensure
        connection1.exec("drop database #{dbName}")
      end
    end
  end

  def testClose
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:open], true)
      connection.close
      assertEquals(MockPGconn.state[:open], false)
      connection.close
      assertEquals(MockPGconn.state[:open], false)
    end
  end

  def testOpen_DefaultArgs
    Connection.mockPgClass do
      connection = Connection.new
      assertEquals(MockPGconn.state[:open], true)
      assertEquals(MockPGconn.state[:openArgs],
                   ["localhost", 5432, "", "", "", nil, nil])
    end
  end

  def testConstructor
    Connection.mockPgClass do
      dbName = randomString
      hostName = randomString
      port = randomInteger
      login = randomString
      password = randomString
      options = randomString
      tty = randomString
      connection = Connection.new('host_name'=>hostName,
                                  'port'=>port,
                                  'options'=>options,
                                  'tty'=>tty,
                                  'db_name'=>dbName,
                                  'login'=>login,
                                  'password'=>password)
      assertEquals(MockPGconn.state[:open], true)
      assertEquals(MockPGconn.state[:openArgs], 
                   [hostName, port, options, tty, dbName, login, password])
      assertEquals(MockPGconn.state[:encoding], 'unicode')
    end
  end

  def testOpen
    Connection.mockPgClass do
      statement = randomString
      Connection.open do |connection|
        assertEquals(MockPGconn.state[:open], true)
        connection.exec(statement)
      end
      assertEquals(MockPGconn.state[:statements], [statement])
      assertEquals(MockPGconn.state[:open], false)
    end
  end

  def testOpen_CloseOnException
    Connection.mockPgClass do
      statement = randomString
      assertException(RuntimeError, "Foo") do
        Connection.open do |connection|
          assertEquals(MockPGconn.state[:open], true)
          raise "Foo"
        end
      end
      assertEquals(MockPGconn.state[:open], false)
    end
  end

  def testOpen_CloseOnException_ExceptionDuringClose
    Connection.mockPgClass do
      statement = randomString
      MockPGconn.state[:close_exception] = RuntimeError.new("Can't close")
      assertException(RuntimeError, "Foo") do
        Connection.open do |connection|
          assertEquals(MockPGconn.state[:open], true)
          raise "Foo"
        end
      end
      assertEquals(MockPGconn.state[:open], false)
    end
  end

  def testOpen_ExceptionDuringClose
    Connection.mockPgClass do
      statement = randomString
      MockPGconn.state[:close_exception] = RuntimeError.new("Can't close")
      assertException(RuntimeError, "Can't close") do
        Connection.open do |connection|
          assertEquals(MockPGconn.state[:open], true)
        end
      end
      assertEquals(MockPGconn.state[:open], false)
    end
  end

  def testDefaultConnection
    default = randomWhatever
    Connection.default = default
    assertEquals(Connection.default, default)
    Connection.default = nil
    assert(Connection.default.is_a?(NullConnection))
  end

  def testExec
    statement = randomString
    result = randomWhatever
    Connection.mockPgClass do
      MockPGconn.state[:results] = [result]
      connection = Connection.new
      assertEquals(connection.exec(statement), result)
      assertEquals(MockPGconn.state[:statements], [statement])
    end
  end

  def testExec_Exception
    Connection.mockPgClass do
      MockPGconn.state[:results] = [RuntimeError.new("Foo")]
      connection = Connection.new
      assertException(RuntimeError, "Foo") do
        connection.exec("foo")
      end
    end
  end

  def testExec_PGError
    testCases = [
      [false, "Foo\n"],
      [true, "Foo\nThe offending statement is: \"bar\""],
    ]
    for statement_in_exception, message in testCases 
      Connection.mockPgClass do
        MockPGconn.state[:results] = [PGError.new("Foo\n")]
        connection = Connection.new
        connection.statement_in_exception = statement_in_exception
        assertException(PGError, message) do
          connection.exec("bar")
        end
      end
    end
  end

  def testQuery
    statement = randomString
    rows = randomWhatever
    Connection.mockPgClass do
      result = Object.new
      class << result
        attr_accessor :result
      end
      result.result = rows
      MockPGconn.state[:results] = [result]
      assertEquals(Connection.new.query(statement), rows)
      assertEquals(MockPGconn.state[:statements], [statement])
    end
  end

  def testStatement_In_Exception
    for value in [false, true]
      connection = Connection.new(testDbArgs.merge('statement_in_exception'=>value))
      assertEquals(connection.statement_in_exception, value)
    end
  end

  def testRealException
    Connection.open(testDbArgs) do |connection|
      assertException(PGError, /ERROR:  (Attribute "foo" not found|column "foo" does not exist)/) do 
        connection.exec("select foo;")
      end
    end
  end

  def testPgconn
    Connection.mockPgClass do
      Connection.open(testDbArgs) do |connection|
        assertEquals(connection.pgconn, MockPGconn.state[:connection])
      end
    end
  end

end

ConnectionTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
