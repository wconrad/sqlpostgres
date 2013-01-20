module SqlPostgres

  # This class creates and manages a cursor.
  #
  # Example:
  #** example: cursor
  #   Transaction.new(connection) do
  #     select = Select.new(connection)
  #     select.select('i')
  #     select.from('foo')
  #     Cursor.new('my_cursor', select, {}, connection) do |cursor|
  #       while !(rows = cursor.fetch).empty?
  #         for row in rows
  #           p row # {"i"=>0}
  #                 # {"i"=>1}
  #                 # {"i"=>2}
  #                 # {"i"=>3}
  #                 # {"i"=>4}
  #           end
  #       end
  #     end
  #   end
  #**
  #
  # Fetching a single row at a time, the default for fetch, is slow.
  # Usually you will want to speed things up by calling, for example,
  # fetch(1000).

  class Cursor

    # Create a cursor.  If a block is given, yield the cursor to the
    # block, closing the cursor when the block returns, and returning
    # results of the block.
    #
    # If no connection is given, then the default connection is used.
    #
    # [name]
    #   The cursor's name
    # [select]
    #   a Select statement
    # [opts]
    #   Options hash.  Keys are:
    #     :scroll=>(boolean)    If true, create a SCROLL cursor.  If false,
    #                           create a NO SCROLL cursor.  If not specified,
    #                           the default is to allow scrolling in cases
    #                           where performance will not suffer.
    #     :hold=>(boolean)      If true, create a WITH HOLD cursor.  If
    #                           false, create a HOLD cursor.  WITHOUT HOLD
    #                           is the default.  A HOLD cursor can be used
    #                           outside of the transaction that created it.
    # [connection]
    #   The database connection

    def initialize(name, select, opts = {}, connection = Connection.default)
      if block_given?
        cursor = self.class.new(name, select, opts, connection)
        result = yield(cursor)
        cursor.close
        result
      else
        @name = name
        @select = select
        @opts = opts
        @connection = connection
        declare_cursor
      end
    end

    # Fetch a row or rows from the cursor.
    #
    # [direction]
    #   A string specifying which row or rows to fetch.  See the
    #   postgres documentation for the "DECLARE" statement.
    #     NEXT
    #     PRIOR
    #     FIRST
    #     LAST
    #     ABSOLUTE count
    #     RELATIVE count
    #     count
    #     ALL
    #     FORWARD
    #     FORWARD count
    #     FORWARD ALL
    #     BACKWARD
    #     BACKWARD count
    #     BACKWARD ALL
    
    def fetch(direction = 'NEXT')
      @select.fetch_by_cursor(@name, direction, @connection)
    end

    # Seek a cursor.  Works exactly the same (and takes the same
    # arguments) as fetch, but returns no rows.
    #
    # [direction]
    #   See #fetch

    def move(direction = 'NEXT')
      statement = "move #{direction} from #{@name}"
      @connection.exec(statement)
    end

    # Close the cursor.  Once closed, it may not be closed or fetched
    # from again.

    def close
      statement = "close #{@name}"
      @connection.exec(statement)
    end

    private

    def declare_cursor
      statement = [
        'declare',
        @name,
        scroll_declaration,
        'cursor',
        hold_declaration,
        'for',
        @select.statement
      ].compact.join(' ')
      @connection.exec(statement)
    end

    def scroll_declaration
      value = @opts.fetch(:scroll, :default)
      if value == :default
        nil
      elsif value
        "SCROLL"
      else
        "NO SCROLL"
      end
    end

    def hold_declaration
      value = @opts.fetch(:hold, :default)
      if value == :default
        nil
      elsif value
        "WITH HOLD"
      else
        "WITHOUT HOLD"
      end
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
