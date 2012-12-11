module SqlPostgres

  # This class holds a connection to the database.

  class Connection

    require 'pg'

    # If true, then PGError exceptions have the offending statement
    # added to them.

    attr_accessor 'statement_in_exception'

    # The underlying instance of PGconn.  This is for when PGconn does
    # something that this library doesn't do.

    attr_reader :pgconn

    @@pgClass = PG
    @@default = nil

    # Get the default connection.  If there isn't one, returns the
    # NullConnection instead.

    def Connection.default
      if @@default.nil?
        NullConnection.new
      else
        @@default
      end
    end

    # Set the default connection.

    def Connection.default=(value)
      @@default = value
    end

    # Open a connection, pass it to the block, then close it.
    # The connection is closed even if an exception occurs.
    # Returns the result of the block.
    #
    # Takes the same arguments as new.
    #
    # Note: If an exception occurs, then any exception from closing
    # the connection is ignored.  This is to avoid masking the original
    # (and presumably more important) exception.

    def Connection.open(*args)
      connection = Connection.new(*args)
      begin
        result = yield(connection)
      rescue
        begin
          connection.close
        rescue
        end
        raise
      else
        connection.close
      end
      result
    end

    # Create a connection.  
    #
    # To create a new connection, pass zero or more of the following
    # arguments They get passed through to PGconn.connect.
    #
    # 'host_name':: 
    #    The host to connect to.  Defaults to 'localhost'
    # 'port':: 
    #    The port to connect to.  Defaults to 5432
    # 'options':: 
    #    Back end options.  Defaults to ''
    # 'tty':: 
    #    Name of TTY for back end messages.  Defaults to ''
    # 'db_name':: 
    #    Database name.  '', the default, means to use the database
    #    with the same name as the user.
    # 'login':: 
    #    Login name.  nil, the default, means to use the user's name.
    #    to nil.
    # 'password'::
    #    Password.  nil, the default, means no password.
    #
    # To wrap an existing connection, pass this argument:
    #
    # 'connection'::
    #   The PGConn instance to wrap.
    #
    # The following arguments influence SqlPostgres's behavior; 
    # they're not actually used to establish the connection to postgres:
    #
    # 'statement_in_exception'::
    #   If true, add the offending statement PGError exceptions.  Defaults
    #   to true.

    def initialize(args = {})
      raise ArgumentError, "Block not allowed" if block_given?
      @pgconn = args['connection']
      if @pgconn.nil?
        hostName = args['host_name'] || "localhost"
        dbName = args['db_name'] || ""
        port = args['port'] || 5432
        options = args['options'] || ""
        tty = args['tty'] || ""
        login = args['login']
        password = args['password']
        @pgconn = @@pgClass.connect(hostName, port, options, tty, dbName, 
                                    login, password)
      end
      @statement_in_exception = args['statement_in_exception']
      @statement_in_exception = true if @statement_in_exception.nil?
      @pgconn.set_client_encoding("unicode")
    end

    # close the connection.  If it's already closed, do nothing.

    def close
      return if @pgconn.nil?
      @pgconn.close
      @pgconn = nil
    end

    # Send an SQL statement to the backend.  Returns a PGResult.  This
    # is just a thin wrapper around PGConn.exec, and exists for when
    # you want to do some SQL that Insert, Update, Select, or
    # Transaction won't do for you (ie, "create temporary table").  
    #
    # If a PGError exception occurs and statement_in_exception is
    # true, then statement is added to the exception.

    def exec(statement)
      begin
        @pgconn.exec(statement)
      rescue PGError => e
        if statement_in_exception
          e = e.exception(e.message + 
                          "The offending statement is: #{statement.inspect}")
        end
        raise e
      end
    end

    # Send an SQL statement to the backend.  Returns an array of arrays.
    #
    # If a PGError exception occurs and statement_in_exception is
    # true, then statement is added to the exception.

    def query(statement)
      result = exec(statement)
      result.send(result_method(result))
    end

    # This is a hook for rspec (mock this method to find out what sql
    # is being executed, and to inject translated results).

    def exec_and_translate(statement, columns)
      translate_pgresult(exec(statement), columns)
    end

    private

    def result_method(result)
      if result.respond_to?(:result)
        :result
      else
        :values
      end
    end

    def translate_pgresult(pgresult, columns)
      pgresult.values.collect do |row|
        hash = {}
        columns.each_with_index do |column, i|
          unless column.converter.nil?
            typeCode = pgresult.ftype(i)
            value = row[i]
            args = [value, @pgconn]
            args << typeCode if column.converter.arity == 3
            hash[column.as || column.value] = 
              value && column.converter.call(*args)
          end
        end
        hash
      end
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
