module SqlPostgres

  # This class creates and executes an SQL delete statement.

  class Delete

    # Create a delete statement
    #
    # [table]
    #   The table name
    # [connection]
    #   If supplied, the connection to use.  If not supplied, use the
    #   default.
    
    def initialize(table, connection = Connection.default)
      @table = table
      @connection = connection
      @where = []
    end

    # Add a "where" condition to this statement.
    #
    # [expression]
    #   The condition.  Should be one of:
    #   [A string] The expression
    #   [An array] An expression converted using #substitute_values

    def where(expression)
      @where << Translate.substitute_values(expression)
    end

    # Return the SQL statement

    def statement
      "delete from #{@table}#{where_clause}"
    end

    # Execute the delete statement
    #
    # [connection]
    #   If present, the connection to use.
    #   If nil, uses the connection passed to new, or if no connection was
    #   passed to new, uses the default connection.

    def exec(connection = @connection)
      connection.exec(statement)
    end

    private

    def where_clause
      if @where.empty?
        ""
      else
        " where " + @where.join(' and ')
      end
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
