module SqlPostgres

  # This class handles an SQL transaction.
  #
  # Example:
  #** example: transaction
  #   Transaction.new(connection) do
  #   
  #     insert = Insert.new('foo', connection)
  #     insert.insert('i', 1)
  #     insert.exec
  #   
  #     insert = Insert.new('foo', connection)
  #     insert.insert('i', 2)
  #     insert.exec
  #   
  #   end
  #**

  class Transaction

    # Create an SQL transaction, yield, and then end the transaction.
    # If an exception occurs, the transaction is aborted.
    #
    # If no connection is given, then the default connection is used.

    def initialize(connection = Connection.default)
      @state = :open
      @finished = false
      @connection = connection
      @connection.exec("begin transaction")
      begin
        result = yield(self)
        commit
        result
      rescue Exception
        abort
        raise
      end
    end

    # Commit this transaction.  This is done for you unless an
    # exception occurs within the block you passed to "new".  Call
    # this when you want to commit the transaction before raising an
    # exception -- in other words, when you want to keep your database
    # changes even though an exception is about to occur.  
    #
    # Example:
    # 
    #** example: transaction_commit 
    #   begin
    #     Transaction.new(connection) do |transaction|
    #       insert = Insert.new('foo', connection)
    #       insert.insert('i', 1)
    #       insert.exec
    #       transaction.commit
    #       raise
    #     end
    #   rescue Exception => e
    #   end
    #   
    #   select = Select.new(connection)
    #   select.select('i')
    #   select.from('foo')
    #   p select.exec            # [{"i"=>1}]
    #**

    def commit
      unless @finished
        do_commit
      end
    end

    # Abort this transaction.  This is done for you when an exception
    # occurs within the block you passed to "new".  Call this when you
    # want to abort a transaction without throwing an exception.
    #
    # Example:
    # 
    #** example: transaction_abort
    #   Transaction.new(connection) do |transaction|
    #     insert = Insert.new('foo', connection)
    #     insert.insert('i', 1)
    #     insert.exec
    #     transaction.abort
    #   end
    #   
    #   select = Select.new(connection)
    #   select.select('i')
    #   select.from('foo')
    #   p select.exec            # []
    #**
    
    def abort
      unless @finished
        do_abort
      end
    end

    private

    def do_commit
      @connection.exec("end transaction")
      @finished = true
    end

    def do_abort
      @connection.exec("abort transaction")
      @finished = true
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
