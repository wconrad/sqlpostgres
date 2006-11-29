require 'date'

module SqlPostgres

  # This class creates and executes an SQL select statement.
  #
  # Example (assuming the values 1, 2 and null are in the database):
  #
  #** Example: select
  #   select = Select.new(connection)
  #   select.select('i')
  #   select.from('foo')
  #   select.order_by('i')
  #   p select.statement   # "select i from foo order by i"
  #   p select.exec        # [{"i"=>1}, {"i"=>2}, {"i"=>nil}]
  #**

  class Select

    # Constructor.  If no connection is given, uses the default.

    def initialize(connection = Connection.default)
      @connection = connection
      @tables = []
      @columns = []
      @joins = []
      @order_by = []
      @where = []
      @group_by = []
      @having = []
      @limit = nil
      @offset = nil
      @distinct = false
      @distinct_on = []
      @set_ops = []
      @for_update = false
    end

    # Add an expression (usually just a simple column name) 
    # to the select statement.
    #
    # [expression]
    #   The expression to put in the select statement.  Should be one of:
    #   [An instance of Select] The Select's SQL statement is put in
    #                           parentheses and added to this statement.
    #   [String or Array] Converted by #substitute_values
    # [as]
    #   The alias name to put in the statement and to use as the hash key
    #   in the result.  If nil, then no alias name appears in the statement
    #   and the expression is used as the hash key.
    #
    # Example:
    #** Example: select_select
    #   select = Select.new(connection)
    #   select.select('i')
    #   select.from('foo')
    #   p select.statement       # "select i from foo"
    #   p select.exec            # [{"i"=>1}]
    #**
    #
    # Example (alias)
    #** Example: select_select_alias
    #   select = Select.new(connection)
    #   select.select('i', 'number')
    #   select.from('foo')
    #   p select.statement       # "select i as number from foo"
    #   p select.exec            # [{"number"=>1}]
    #**
    #
    # Example (expression)
    #** Example: select_select_expression
    #   pi = 3.14
    #   select = Select.new(connection)
    #   select.select(['d * %s', pi], 'c')
    #   select.from('circles')
    #   p select.statement       # "select d * 3.14 as c from circles"
    #   p select.exec            # [{"c"=>6.28}]
    #**

    def select(expression, as = nil, &converter)
      converter ||= AutoConverter
      expression = if expression.is_a?(Select)
                     "(#{expression.statement})" 
                   else
                     Translate.substitute_values(expression)
                   end
      @columns << Column.new(expression, as, converter)
    end
    
    # Select a literal, automatically selecting its result type.
    #
    # [value]
    #   The value to put in the statement.  This can be any of these types:
    #   * nil
    #   * Integer
    #   * Float
    #   * String
    #   * true or false
    #   * #PgTime
    #   * #PgInterval
    #   * #PgTimeWithTimeZone
    #   * #PgTimestamp
    #   * #PgPoint
    #   * #PgLineSegment
    #   * #PgBox
    #   * #PgPath
    #   * #PgPolygon
    #   * #PgCircle
    #   * #PgBit
    #   * #PgInet
    #   * #PgCidr
    #   * #PgMacAddr
    #
    # [as]
    #   The alias name to put in the statement and to use as the hash
    #   key in the result.  If nil, then no alias name appears in the
    #   statement and the value itself is used as the hash key.
    #
    # Example:
    #** Example: select_select_literal
    #   select = Select.new(connection)
    #   select.select_literal(2, 'n')
    #   select.select_literal('foo', 't')
    #   p select.statement         # "select 2 as n, 'foo' as t"
    #   p select.exec              # [{"n"=>2, "t"=>"foo"}]
    #**

    def select_literal(value, as = nil)
      select(["%s", value], as)
    end

    # Add "distinct" to this statement.
    #
    # Example:
    #** Example: select_distinct
    #   select = Select.new
    #   select.distinct
    #   select.select('i')
    #   select.from('foo')
    #   p select.statement             # "select distinct i from foo"
    #**

    def distinct
      @distinct = true
    end

    # Add "distinct on" to this statement.
    # "distinct on" is a postgres extension.
    #
    # Example:
    #** Example: select_distinct_on
    #   select = Select.new
    #   select.distinct_on('i')
    #   select.select('integer', 'i')
    #   select.select('integer', 'j')
    #   select.from('foo')
    #   p select.statement            # "select distinct on (i) i, j from 
    #                                 # foo"
    #**

    def distinct_on(expression)
      @distinct_on << expression
    end

    # Add the "from" clause to the statement.
    #
    # [table]
    #   What's being selected from, which is either
    #   * A table name, or
    #   * a Select statement
    # [as]
    #   The alias name, or nil if there isn't one
    #
    # Table example:
    #** Example: select_from
    #   select = Select.new
    #   select.select('i')
    #   select.from('foo')
    #   p select.statement    # "select i from foo"
    #**
    #
    # Subselect example:
    #** Example: select_from_subselect
    #   subselect = Select.new
    #   subselect.select('i')
    #   subselect.from('foo')
    #   select = Select.new
    #   select.select('i')
    #   select.from(subselect, 'bar')
    #   p select.statement  # "select i from (select i from foo) as bar"
    #**

    def from(table, as = nil)
      table = "(#{table.statement})" if table.is_a?(Select)
      @tables << [table, as].compact.join(' as ')
    end

    # Add the "union" set operation to this statement.
    # You may call this multiple times.
    #
    # The right-hand-side of the union is put in parentheses.
    # This makes it possible to force the order when doing multiple
    # set operations.
    #
    # Example
    #** Example: select_union
    #   select2 = Select.new
    #   select2.select('i')
    #   select2.from('bar')
    #   select1 = Select.new
    #   select1.select('i')
    #   select1.from('foo')
    #   select1.union(select2)
    #   p select1.statement    # "select i from foo union (select i from 
    #                          # bar)"
    #**

    def union(select)
      add_set_op('union', select)
    end

    # Add the "union all" set operation to this statement.
    # See #union.

    def union_all(select)
      add_set_op('union all', select)
    end

    # Add the "intersect" set operation to this statement.
    # See #union.

    def intersect(select)
      add_set_op('intersect', select)
    end

    # Add the "intersect all" set operation to this statement.
    # See #union.

    def intersect_all(select)
      add_set_op('intersect all', select)
    end

    # Add the "except" set operation to this statement.
    # See #union.

    def except(select)
      add_set_op('except', select)
    end

    # Add the "except all" set operation to this statement.
    # See #union.

    def except_all(select)
      add_set_op('except all', select)
    end

    # Add a natural join to this statement.
    #
    # Example:
    #** Example: select_natural_join
    #   select = Select.new
    #   select.select('i')
    #   select.from('foo')
    #   select.natural_join('bar')
    #   p select.statement        # "select i from foo natural join bar"
    #**

    def natural_join(table)
      @joins << "natural join #{table}"
    end

    # Add a "join using" to this statement.
    #
    # [joinType]
    #   One of:
    #     * 'inner'
    #     * 'left outer'
    #     * 'right outer'
    #     * 'full outer'
    # [table]
    #   The table being joined
    # [*columns]
    #   One or more column names.
    #
    # Example:
    #** Example: select_join_using
    #   select = Select.new
    #   select.select('i')
    #   select.from('foo')
    #   select.join_using('inner', 'bar', 'i', 'j')
    #   p select.statement  # "select i from foo inner join bar using (i, j)"
    #**

    def join_using(joinType, table, *columns)
      @joins << "#{joinType} join #{table} using (#{columns.join(', ')})"
    end

    # Add a "join on" to this statement.
    #
    # [joinType]
    #   One of:
    #     * 'inner'
    #     * 'left outer'
    #     * 'right outer'
    #     * 'full outer'
    # [table]
    #   The table being joined
    # [condition]
    #   A string or array that will be converted by #substitute_values
    #   and inserted into the statement.
    #
    # Example:
    #** Example: select_join_on
    #   select = Select.new
    #   select.select('i')
    #   select.from('foo')
    #   select.join_on('inner', 'bar', 'foo.i = bar.j')
    #   p select.statement  # "select i from foo inner join bar on (foo.i = 
    #                       # bar.j)"
    #**

    def join_on(joinType, table, condition)
      @joins << ("#{joinType} join #{table} on "\
                 "(#{Translate.substitute_values(condition)})")
    end

    # Add a "cross join" to this statement.
    #
    # Example:
    #** Example: select_cross_join
    #   select = Select.new
    #   select.select('i')
    #   select.from('foo')
    #   select.cross_join('bar')
    #   p select.statement       # "select i from foo cross join bar"
    #**

    def cross_join(table)
      @joins << "cross join #{table}"
    end

    # Add an "order by" to this statement.  You can call this as many
    # times as you need.
    #
    # [expression]
    #   A string or array that will be converted by #substitute_values
    #   and inserted into the statement.
    # [ordering]
    #   One of:
    #   'asc':: ascending
    #   'desc':: descending
    #   nil:: default ordering, which is ascending
    #
    # Example:
    #** Example: select_order_by
    #   select = Select.new
    #   select.select('i')
    #   select.select('j')
    #   select.from('foo')
    #   select.order_by('i')
    #   select.order_by('j', 'desc')
    #   p select.statement   # "select i, j from foo order by i, j desc"
    #**

    def order_by(expression, ordering = nil)
      @order_by << 
        [Translate.substitute_values(expression), ordering].compact.join(' ')
    end

    # Add a "where" condition to this statement.
    #
    # [expression]
    #   The condition.  Should be one of:
    #   [A string] The expression
    #   [An array] An expression converted using #substitute_values
    #
    # Example (string)
    #** Example: select_where_string
    #   select = Select.new
    #   select.select('i')
    #   select.from('foo')
    #   select.where('i > 0')
    #   p select.statement     # "select i from foo where i > 0"
    #**
    #
    # Example (array)
    #** Example: select_where_array
    #   select = Select.new
    #   select.select('age')
    #   select.from('person')
    #   select.where(['name = %s', 'Smith'])
    #   p select.statement     # "select age from person where name = 
    #                          # 'Smith'"
    #**
    #
    # Example (in)
    #** Example: select_where_in
    #   select = Select.new
    #   select.select('s')
    #   select.from('foo')
    #   select.where(['s in %s', [:in, 'foo', 'bar']])
    #   p select.statement     # "select s from foo where s in ('foo', 
    #                          # 'bar')"
    #**

    def where(expression)
      @where << Translate.substitute_values(expression)
    end

    # Add a "group by" to this statement.
    #
    # [expression]
    #   A string or array that will be converted by #substitute_values
    #   and inserted into the statement.
    #
    # Example
    #** Example: select_group_by
    #   select = Select.new
    #   select.select('i')
    #   select.select('count(*)', 'count')
    #   select.from('foo')
    #   select.group_by('i')
    #   p select.statement     # "select i, count(*) as count from foo group 
    #                          # by i"
    #**

    def group_by(expression)
      @group_by << Translate.substitute_values(expression)
    end

    # Add a "having" clause to this statement.
    #
    # [expression]
    #   A string or array that will be converted by #substitute_values
    #   and inserted into the statement.
    #
    # Example
    #** Example: select_having
    #   select = Select.new
    #   select.select('i')
    #   select.select('count(*)', 'count')
    #   select.from('foo')
    #   select.group_by('i')
    #   select.having('i < 10')
    #   p select.statement       # "select i, count(*) as count from foo 
    #                            # group by i having i < 10"
    #**

    def having(expression)
      @having << Translate.substitute_values(expression)
    end

    # Add a "limit" clause to the statement.
    #
    # Example:
    #** Example: select_limit
    #   select = Select.new
    #   select.select('i')
    #   select.from('foo')
    #   select.order_by('i')
    #   select.limit(1)
    #   p select.statement   # "select i from foo order by i limit 1"
    #**

    def limit(value)
      @limit = value
    end

    # Add an "offset" clause to the statement.
    #
    # Example:
    #** Example: select_offset
    #   select = Select.new
    #   select.select('i')
    #   select.from('foo')
    #   select.order_by('i')
    #   select.offset(1)
    #   p select.statement     # "select i from foo order by i offset 1"
    #**

    def offset(value)
      @offset = value
    end

    # Add "for update" to the statement.
    #
    # Example:
    #** Example: select_for_update
    #   select = Select.new
    #   select.select('i')
    #   select.from('foo')
    #   select.for_update
    #   p select.statement     # "select i from foo for update"
    #**

    def for_update
      @for_update = true
    end

    # Return the SQL statement.

    def statement
      "select#{distinct_clause} #{expression_list}"\
      "#{tableExpression}#{join_clause}"\
      "#{where_clause}#{set_ops_clause}#{group_by_clause}#{having_clause}#{order_by_clause}"\
      "#{limit_clause}#{offset_clause}#{for_update_clause}"
    end

    # Execute the statement and return an array of hashes with the result.
    #
    # [connection]
    #   If present, the connection to use.
    #   If nil, uses the connection passed to new or, if no connection was
    #   passed to new, uses the default connection.

    def exec(connection = @connection)
      translate_pgresult(connection.exec(statement))
    end

    private

    Column = Struct.new(:value, :as, :converter)

    # OIDs for Postgresql data types.  These must match 
    # postgresql/server/catalog/pg_type.h.

    module Types
      BOOLEAN = 16
      BYTEA = 17
      QCHAR = 18
      NAME = 19
      BIGINT = INT8 = BIGSERIAL = SERIAL8 = 20
      SMALLINT = 21
      INTEGER = INT = INT4 = SERIAL = 23
      TEXT = 25
      OID = 26
      POINT = 600
      LSEG = 601
      PATH = 602
      BOX = 603
      POLYGON = 604
      CIDR = 650
      ARRAY_CIDR = 651
      REAL = 700
      DOUBLE_PRECISION = FLOAT8 = 701
      UNKNOWN = 705
      CIRCLE = 718
      ARRAY_CIRCLE = 719
      MACADDR = 829
      INET = 869
      ARRAY_BOOLEAN = 1000
      ARRAY_BYTEA = 1001
      ARRAY_QCHAR = 1002
      ARRAY_NAME = 1003
      ARRAY_SMALLINT = 1005
      ARRAY_INTEGER = 1007
      ARRAY_TEXT = 1009
      ARRAY_CHARACTER = 1014
      ARRAY_VARCHAR = 1015
      ARRAY_BIGINT = 1016
      ARRAY_POINT = 1017
      ARRAY_LSEG = 1018
      ARRAY_PATH = 1019
      ARRAY_BOX = 1020
      ARRAY_REAL = 1021
      ARRAY_DOUBLE_PRECISION = 1022
      ARRAY_POLYGON = 1027
      ARRAY_MACADDR = 1040
      ARRAY_INET = 1041
      CHARACTER = CHAR = 1042
      VARCHAR = CHARACTER_VARYING = 1043
      DATE = 1082
      TIME = 1083
      TIMESTAMP = TIMESTAMP_WITHOUT_TIME_ZONE = 1114
      ARRAY_TIMESTAMP = 1115
      ARRAY_DATE = 1182
      ARRAY_TIME = 1183
      TIMESTAMP_WITH_TIME_ZONE = 1184
      ARRAY_TIMESTAMP_WITH_TIME_ZONE = 1185
      INTERVAL = 1186
      ARRAY_INTERVAL = 1187
      ARRAY_NUMERIC = 1231
      TIME_WITH_TIME_ZONE = 1266
      ARRAY_TIME_WITH_TIME_ZONE = 1270
      BIT = 1560
      ARRAY_BIT = 1561
      VARBIT = 1562
      ARRAY_VARBIT = 1563
      NUMERIC = DECIMAL = 1700
    end

    # Converters used to translate strings into Ruby types.

    BitConverter = proc { |s| PgBit.from_sql(s) }
    BooleanConverter = proc { |s| s == 't' }
    BoxConverter = proc { |s| PgBox.from_sql(s) }
    ByteaConverter = proc { |s| Translate.unescape_bytea(s) }
    CidrConverter = proc { |s| PgCidr.from_sql(s) }
    CircleConverter = proc { |s| PgCircle.from_sql(s) }
    DateConverter = proc { |s| Translate.sql_to_date(s) }
    FloatConverter = proc { |s| s.to_f }
    InetConverter = proc { |s| PgInet.from_sql(s) }
    IntegerConverter = proc { |s| s.to_i }
    IntervalConverter = proc { |s| PgInterval.from_sql(s) }
    LsegConverter = proc { |s| PgLineSegment.from_sql(s) }
    MacAddrConverter = proc { |s| PgMacAddr.from_sql(s) }
    PathConverter = proc { |s| PgPath.from_sql(s) }
    PointConverter = proc { |s| PgPoint.from_sql(s) }
    PolygonConverter = proc { |s| PgPolygon.from_sql(s) }
    QCharConverter = proc { |s| Translate.unescape_qchar(s) }
    StringConverter = proc { |s| s }
    TimeConverter = proc { |s| PgTime.from_sql(s) }
    TimeStringConverter = proc { |s| Time.local(*s.split(/:/)) }
    TimeWithTimeZoneConverter = proc { |s| PgTimeWithTimeZone.from_sql(s) }
    TimestampConverter = proc { |s| PgTimestamp.from_sql(s) }
    TimestampTzConverter = proc { |s| Translate.sql_to_datetime(s) }

    # Map each base (non-array) type to a converter.

    CONVERTERS = {
      Types::BIGINT => IntegerConverter,
      Types::BIT => BitConverter,
      Types::BOOLEAN => BooleanConverter,
      Types::BOX => BoxConverter,
      Types::BYTEA => ByteaConverter,
      Types::CHARACTER => StringConverter,
      Types::CIDR => CidrConverter,
      Types::CIRCLE => CircleConverter,
      Types::DATE => DateConverter,
      Types::DOUBLE_PRECISION => FloatConverter,
      Types::INET => InetConverter,
      Types::INTEGER => IntegerConverter,
      Types::INTERVAL => IntervalConverter,
      Types::LSEG => LsegConverter,
      Types::MACADDR => MacAddrConverter,
      Types::NAME => StringConverter,
      Types::NUMERIC => FloatConverter,
      Types::OID => IntegerConverter,
      Types::PATH => PathConverter,
      Types::POINT => PointConverter,
      Types::POLYGON => PolygonConverter,
      Types::QCHAR => QCharConverter,
      Types::REAL => FloatConverter,
      Types::SMALLINT => IntegerConverter,
      Types::TEXT => StringConverter,
      Types::TIME => TimeConverter,
      Types::TIMESTAMP => TimestampConverter,
      Types::TIMESTAMP_WITH_TIME_ZONE => TimestampTzConverter,
      Types::TIME_WITH_TIME_ZONE => TimeWithTimeZoneConverter,
      Types::UNKNOWN => StringConverter,
      Types::VARBIT => BitConverter,
      Types::VARCHAR => StringConverter,
    }

    # Map each array type to its base type.

    ARRAY_ELEMENT_TYPES = {
      Types::ARRAY_BIGINT => Types::BIGINT,
      Types::ARRAY_BIT => Types::BIT,
      Types::ARRAY_BOOLEAN => Types::BOOLEAN,
      Types::ARRAY_BOX => Types::BOX,
      Types::ARRAY_BYTEA => Types::BYTEA,
      Types::ARRAY_CHARACTER => Types::CHARACTER,
      Types::ARRAY_INET => Types::INET,
      Types::ARRAY_CIDR => Types::CIDR,
      Types::ARRAY_CIRCLE => Types::CIRCLE,
      Types::ARRAY_DATE => Types::DATE,
      Types::ARRAY_DOUBLE_PRECISION => Types::DOUBLE_PRECISION,
      Types::ARRAY_INTEGER => Types::INTEGER,
      Types::ARRAY_INTERVAL => Types::INTERVAL,
      Types::ARRAY_LSEG => Types::LSEG,
      Types::ARRAY_MACADDR => Types::MACADDR,
      Types::ARRAY_NAME => Types::NAME,
      Types::ARRAY_NUMERIC => Types::NUMERIC,
      Types::ARRAY_PATH => Types::PATH,
      Types::ARRAY_POINT => Types::POINT,
      Types::ARRAY_POLYGON => Types::POLYGON,
      Types::ARRAY_QCHAR => Types::QCHAR,
      Types::ARRAY_REAL => Types::REAL,
      Types::ARRAY_SMALLINT => Types::SMALLINT,
      Types::ARRAY_TEXT => Types::TEXT,
      Types::ARRAY_TIME => Types::TIME,
      Types::ARRAY_TIMESTAMP => Types::TIMESTAMP,
      Types::ARRAY_TIMESTAMP_WITH_TIME_ZONE => Types::TIMESTAMP_WITH_TIME_ZONE,
      Types::ARRAY_TIME_WITH_TIME_ZONE => Types::TIME_WITH_TIME_ZONE,
      Types::ARRAY_VARBIT => Types::VARBIT,
      Types::ARRAY_VARCHAR => Types::VARCHAR,
    }

    AutoConverter = proc { |s, type_code|
      array_element_type = ARRAY_ELEMENT_TYPES[type_code]
      if !array_element_type.nil?
        s = Translate.sql_to_array(s)
        type_code = array_element_type
      end
      converter = CONVERTERS[type_code]
      if converter.nil?
        raise "Unknown column type code: #{type_code}"
      end
      Translate.deep_collect(s) do |e|
        converter.call(e)
      end
    }

    def data_type_for(value, as)
      return nil if as.nil?
      if value.is_a?(Float)
        'float'
      elsif value.is_a?(Integer)
        'integer'
      elsif value == true || value == false
        'boolean'
      elsif value.is_a?(Time)
        'time'
      else
        'string'
      end
    end

    def distinct_clause
      if @distinct
        " distinct"
      elsif !@distinct_on.empty?
        " distinct on (#{@distinct_on.join(', ')})"
      else
        ""
      end
    end

    def add_set_op(op, select)
      @set_ops << [op, select.statement]
    end

    def expression_list
      @columns.collect do |column|
        [column.value, column.as].compact.join(' as ')
      end.join(', ')
    end

    def tableExpression
      if @tables.empty?
        ""
      else
        " from #{@tables.join(', ')}"
      end
    end

    def join_clause
      if @joins.empty?
        ""
      else
        " " + @joins.join(' ')
      end
    end

    def set_ops_clause
      if @set_ops.empty?
        ""
      else
        ' ' + @set_ops.collect do |op, statement|
          "#{op} (#{statement})"
        end.join(' ')
      end
    end

    def order_by_clause
      if @order_by.empty?
        ""
      else
        " order by " + @order_by.join(', ')
      end
    end

    def limit_clause
      if @limit.nil?
        ""
      else
        " limit #{@limit}"
      end
    end

    def offset_clause
      if @offset.nil?
        ""
      else
        " offset #{@offset}"
      end
    end

    def for_update_clause
      if @for_update
        " for update"
      else
        ""
      end
    end

    def where_clause
      if @where.empty?
        ""
      else
        " where " + @where.join(' and ')
      end
    end

    def group_by_clause
      if @group_by.empty?
        ""
      else
        " group by " + @group_by.join(', ')
      end
    end

    def having_clause
      if @having.empty?
        ""
      else
        " having " + @having.join(' and ')
      end
    end

    def translate_pgresult(pgresult)
      pgresult.result.collect do |row|
        hash = {}
        @columns.each_with_index do |column, i|
          unless column.converter.nil?
            typeCode = pgresult.type(i)
            value = row[i]
            args = [value]
            args << typeCode if column.converter.arity == 2
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
