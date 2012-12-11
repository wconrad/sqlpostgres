module SqlPostgres

  # This class creates and executes an SQL insert statement.
  #
  # Example:
  #** Example: insert
  #   insert = Insert.new('foo', connection)
  #   insert.insert('i', 1)
  #   insert.insert('t', 'foo')
  #   p insert.statement           # "insert into foo (i, t) values (1, 
  #                                # E'foo')"
  #   insert.exec
  #**

  class Insert

    # Create an insert statement
    #
    # [table]
    #   The table name
    # [connection]
    #   If supplied, the connection to use.  If not supplied, use the
    #   default.
    
    def initialize(table, connection = Connection.default)
      @table = table
      @connection = connection
      @columns = []
      @values = []
      @query = nil
    end

    # Add a column to the statement.  This is for all column types
    # *except* bytea.
    #
    # [column]
    #   The column name
    # [value]
    #   The value to add.  The value is SQL escaped.
    #   Should be one of:
    #   * a String
    #   * an Integer
    #   * a Float
    #   * a Time
    #   * false
    #   * true
    #   * nil
    #   * a Select
    #   * :default
    #   * :no_value
    # 
    # Special values:
    # [a Select]
    #   The select's SQL is added in parentheses
    # [:default] 
    #   Add the SQL keyword "default" to the statement.
    # [:no_value] 
    #     Do not add a value for this column.  This is used when the
    #     values are being provided by a Select statement.
    #
    # Example (simple)
    #** Example: insert_insert
    #   insert = Insert.new('foo')
    #   insert.insert('t', 'bar')
    #   p insert.statement         # "insert into foo (t) values (E'bar')"
    #**
    #
    # Example (select)
    #** Example: insert_insert_select
    #   select = Select.new
    #   select.select('j')
    #   select.from('bar')
    #   select.limit(1)
    #   insert = Insert.new('foo')
    #   insert.insert('i', select)
    #   p insert.statement           # "insert into foo (i) values ((select j 
    #                                # from bar limit 1))"
    #**
    #
    # Example (default)
    #** Example: insert_insert_default
    #   insert = Insert.new('foo')
    #   insert.insert('i', :default)
    #   p insert.statement             # "insert into foo (i) values 
    #                                  # (default)"
    #**

    def insert(column, value = :no_value)
      @columns << column
      @values << Translate.escape_sql(value) unless value == :no_value
    end

    # Insert into an array (int[], text[], etc) column.  This is not
    # for byte array (bytea) column types: For that, call
    # #insert_bytea.
    #
    # [column]
    #   The column name
    # [value]
    #  The value to add.
    #
    # This is used for inserting literals and expressions.  To insert
    # the result of an SQL query, or to insert the default value,
    # call #insert.

    def insert_array(column, value)
      @columns << column
      @values << Translate.escape_array(value)
    end

    # Insert into a bytea column.  You must use this function, not
    # #insert, when inserting a string into a bytea column.  That's
    # because bytea columns need special escaping.
    #
    # [column]
    #   The column name
    # [value]
    #   The value to add.
    #   Should be one of:
    #   * a String
    #   * :default
    #   * :no_value
    # 
    # Special values:
    # [a Select]
    #   The select's SQL is added in parentheses
    # [:default] 
    #   Add the SQL keyword "default" to the statement.
    # [:no_value] 
    #     Do not add a value for this column.  This is used when the
    #     values are being provided by a Select statement.
    #
    # Example:
    #** Example: insert_bytea
    #   insert = Insert.new('foo')
    #   insert.insert_bytea('t', "\000\001\002\003")
    #   p insert.statement     # "insert into foo (t) values 
    #                          # (E'\\\\000\\\\001\\\\002\\\\003')"
    #**

    def insert_bytea(column, value = :no_value)
      @columns << column
      @values << Translate.escape_bytea(value, @connection.pgconn) unless value == :no_value
    end

    # Insert into a bytea[] (bytea array) column.  You must use this
    # function, not #insert or #insert_array, because bytea[] columns
    # need special escaping.
    #
    #** Example: insert_bytea_array
    #   insert = Insert.new('foo')
    #   insert.insert_bytea_array('t', ["foo", "\000bar\nbaz"])
    #   p insert.statement     # "insert into foo (t) values 
    #                          # ('{\"foo\",\"\\\\\\\\000bar\nbaz\"}')"
    #   
    #**

    def insert_bytea_array(column, value = :no_value)
      @columns << column
      @values << Translate.escape_bytea_array(value) unless value == :no_value
    end

    # Insert into a "char" column.  This is a Postgres specific data
    # type that is different than char or character (yes, the quotes
    # are part of the type name).  "char" values are escaped
    # differently than normal test, so be sure to use this method and
    # not #insert when inserting into a "char" column.
    #
    # [column]
    #   The column name
    # [value]
    #   A string of length 1
    #
    # Example:
    #** Example: insert_qchar
    #**

    def insert_qchar(column, value = :no_value)
      @columns << column
      @values << Translate.escape_qchar(value)
    end

    # Insert the results of a select statement
    #
    # Example:
    #** Example: insert_select
    #   select = Select.new
    #   select.select('i')
    #   select.from('bar')
    #   insert = Insert.new('foo')
    #   insert.insert('i')
    #   insert.select(select)
    #   p insert.statement     # "insert into foo (i) select i from bar"
    #**

    def select(select)
      @query = select.statement
    end

    # Define return clause
    #
    # Example: (simple)
    #** Example: insert_returning
    #   insert = Insert.new('foo')
    #   insert.insert('i', 3)
    #   insert.returning('i')
    #   p insert.statement       # "insert into foo (i) values (3) returning i
    #
    # Example: (expression_with_alias)
    #** Example: insert_returning_with_alias
    #   insert = Insert.new('foo')
    #   insert.insert('i', 3)
    #   insert.returning('i*3', 'calc')
    #   p insert.statement       # "insert into foo (i) values (3) returning i*3 as calc

    def returning(expression, name=nil)
      str = "returning #{expression}"
      str += " as #{name}" if name
      @returning_expression = str
    end

    # insert default values
    #
    # Example:
    #** Example: insert_default_values
    #   insert = Insert.new('foo')
    #   insert.default_values
    #   p insert.statement     # "insert into foo default values"
    #**

    def default_values
      @query = "default values"
    end

    # Return the SQL statement.  Especially useful for debugging.

    def statement
      [
        "insert into",
        @table,
        column_list,
        query_expression,
      ].compact.join(' ')
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

    def query_expression
      @query || source
    end

    def column_list
      "(#{@columns.join(', ')})" unless @columns.empty?
    end

    def source
      "values (#{@values.join(', ')}) #{@returning_expression}".strip
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
