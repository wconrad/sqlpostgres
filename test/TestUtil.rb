module TestUtil

  require 'TestConfig'

  include TestConfig
  include SqlPostgres

  def testDbArgs
    {
      'db_name' => TEST_DB_NAME,
      'port'=> TEST_DB_PORT,
      'encoding' => TEST_CLIENT_ENCODING,
    }
  end

  def testForTestDb
    begin
      Connection.new(testDbArgs)
    rescue PGError => message
      puts "Creating test database"
      run_psql "create database #{TEST_DB_NAME} with encoding '#{TEST_DB_ENCODING}' template template0"
    end
  end

  def removeTestDb
    puts "Removing test database"
    run_psql "drop database #{TEST_DB_NAME}"
  end

  def run_psql(command)
    command = "psql -p #{TEST_DB_PORT} -c #{command.inspect} 2>&1"
    output = `#{command}`
    if $? != 0
      $stderr.puts "Failed: #{command}"
      $stderr.print output
      exit(1)
    end
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
    s = (floor..255).to_a.collect do |i|
      i.chr
    end.join
    if s.respond_to?(:force_encoding)
      s = s.force_encoding('ASCII-8BIT')
    end
    s
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
