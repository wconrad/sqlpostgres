module SqlPostgres

  # This class creates and executes an SQL update statement.
  #
  # Example:
  #** Example: update
  #   update = Update.new('foo', connection)
  #   update.set('i', 2)
  #   p update.statement    # "update foo set i = 2"
  #   update.exec
  #**

  class Update

    # Create an update statement.
    #
    # [table]
    #   The table name
    # [connection]
    #   The connection to use.  If nil, use the default connection instead.

    def initialize(table, connection = Connection.default)
      @table = table
      @connection = connection
      @set_clauses = []
      @conditions = []
      @only = false
    end

    # Add "only" to this statement.  This is a postgres extension
    # which causes the update to *not* apply to derived tables.
    #
    # Example:
    #** Example: update_only
    #   update = Update.new('foo')
    #   update.only
    #   update.set('i', 0)
    #   p update.statement    # "update only foo set i = 0"
    #**

    def only
      @only = true
    end

    # Set a column to a value.
    #
    # [column]
    #   The column name
    # [value]
    #   The value to set the column to.  Ruby data types are converted
    #   to SQL automatically using #escape_sql.
    #
    # Example showing a few different types:
    #** Example: update_set
    #   update = Update.new('foo')
    #   update.set('name', 'Fred')
    #   update.set('hire_date', Time.local(2002, 1, 1))
    #   p update.statement      # "update foo set name = E'Fred', hire_date = 
    #                           # timestamp '2002-01-01 00:00:00.000000'"
    #**
    #
    # Example showing a subselect:
    #** Example: update_set_subselect
    #   select = Select.new
    #   select.select('j')
    #   select.from('bar')
    #   select.where(["i = foo.i"])
    #   update = Update.new('foo')
    #   update.set('i', select)
    #   p update.statement         # "update foo set i = (select j from bar 
    #                              # where i = foo.i)"
    #**
    #
    # Example showing an expression:
    #** Example: update_set_expression
    #   update = Update.new('foo')
    #   update.set('i', ['i + 1'])
    #   p update.statement           # "update foo set i = i + 1"
    #**

    def set(column, value)
      @set_clauses << [column, Translate.escape_sql(value)].join(' = ')
    end

    # Set a bytea column.  You must use this function, not #set, when
    # updating a bytea column.  That's because bytea columns need
    # special escaping.
    #
    # [column]
    #   The column name
    # [value]
    #   The value to add.
    #
    # Example:
    #** Example: update_set_bytea
    #   update = Update.new('foo')
    #   update.set_bytea('name', "\000\377")
    #   p update.statement      # "update foo set name = E'\\\\000\\\\377'"
    #**

    def set_bytea(column, value)
      @set_clauses << [column, Translate.escape_bytea(value, @connection.pgconn)].join(' = ')
    end

    # Set a column to an array.
    #
    # [column]
    #   The column name
    # [value]
    #   The value to set the column to.  Ruby data types are converted
    #   to SQL automatically using #escape_array.
    #
    # Example:
    #** Example: update_set_array
    #   update = Update.new('foo')
    #   update.set_array('i', [1, 2, 3])
    #   p update.statement      # "update foo set i = ARRAY[1, 2, 3]"
    #**

    def set_array(column, value)
      @set_clauses << [column, Translate.escape_array(value)].join(' = ')
    end

    # Add a where clause to the statement.
    #
    # [expression]
    #   A string or array, converted using #substitute_values
    #
    # Example:
    #** Example: update_where
    #   update = Update.new('foo')
    #   update.set('i', 1)
    #   update.where(['t = %s', "bar"])
    #   p update.statement     # "update foo set i = 1 where t = E'bar'"
    #**

    def where(condition)
      @conditions << Translate.substitute_values(condition)
    end

    # Return the SQL statement.  Especially useful for debugging.

    def statement
      "update#{only_option} #{@table} set #{set_clause_list}#{where_clause}"
    end

    # Execute the statement.
    #
    # [connection]
    #   If present, the connection to use.
    #   If nil, uses the connection passed to new or, if no connection was
    #   passed to new, uses the default connection.

    def exec(connection = @connection)
      connection.exec(statement)
    end

    private

    def set_clause_list
      @set_clauses.join(', ')
    end

    def where_clause
      if @conditions.empty?
        ""
      else
        " where #{@conditions.join(' and ')}"
      end
    end

    def only_option
      if @only
        " only"
      else
        ""
      end
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
