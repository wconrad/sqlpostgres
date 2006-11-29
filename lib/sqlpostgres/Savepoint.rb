module SqlPostgres

  # This class handles a savepoint.
  #
  # Example:
  #** example: savepoint
  #   Transaction.new(connection) do
  #   
  #     insert = Insert.new('foo', connection)
  #     insert.insert('i', 1)
  #     insert.exec
  #   
  #     Savepoint.new('bar', connection) do |sp|
  #       insert = Insert.new('foo', connection)
  #       insert.insert('i', 2)
  #       sp.abort
  #     end
  #   
  #     insert = Insert.new('foo', connection)
  #     insert.insert('i', 3)
  #     insert.exec
  #   
  #   end
  #   
  #   p connection.query("select i from foo order by i") #[["1"], ["3"]]
  #**

  class Savepoint

    # Create an SQL savepoint, yield, and then commit the savepoint.
    # If an exception occurs, the savepoint is aborted.
    #
    # If no connection is given, then the default connection is used.

    def initialize(name, connection = Connection.default)
      @name = name
      @state = :open
      @finished = false
      @connection = connection
      @connection.exec("savepoint #{name}")
      begin
        result = yield(self)
        commit
        result
      rescue Exception
        abort
        raise
      end
    end

    # Commit this savepoit.  This is done for you unless an
    # exception occurs within the block you passed to "new".  Call
    # this when you want to commit the savepoint before raising an
    # exception -- in other words, when you want to keep your database
    # changes even though an exception is about to occur.  

    def commit
      unless @finished
        do_commit
      end
    end

    # Abort this savepoint.  This is done for you when an exception
    # occurs within the block you passed to "new".  Call this when you
    # want to abort a savepoint without throwing an exception.
    
    def abort
      unless @finished
        do_abort
      end
    end

    private

    def do_commit
      release_savepoint
      @finished = true
    end

    def do_abort
      @connection.exec("rollback to #{@name}")
      release_savepoint
      @finished = true
    end

    def release_savepoint
      @connection.exec("release savepoint #{@name}")
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
