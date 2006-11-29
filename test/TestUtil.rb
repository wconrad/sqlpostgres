module TestUtil

  require 'TestConfig'

  include TestConfig
  include SqlPostgres

  def testDbArgs
    {'db_name'=>TEST_DB_NAME}
  end

  def makeTestConnection
    if block_given?
      Connection.open(testDbArgs) do |connection|
        yield(connection)
      end
    else
      Connection.new(testDbArgs)
    end
  end

  def setDefaultConnection(connection)
    oldDefault = Connection.default
    Connection.default = connection
    begin
      yield
    ensure
      Connection.default = oldDefault
    end
  end

  def testTableName(suffix)
    [TEST_DB_PREFIX, suffix].join('')
  end
  
  def table1
    testTableName("foo")
  end

  def table2
    testTableName("bar")
  end

  def table3 
    testTableName("baz")
  end

  def allCharactersExceptNull
    allCharacters(1)
  end

  def allCharacters(floor = 0)
    (floor..255).to_a.collect do |i| i.chr end.join
  end

  def setenv(name, value)
    old_value = ENV[name]
    ENV[name] = value
    begin
      yield
    ensure
      ENV[name] = old_value
    end
  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
