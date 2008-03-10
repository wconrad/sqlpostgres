require 'bigdecimal'

module SqlPostgres

  # Translation functions.  These are internal and should not be used
  # by clients unless you want extra work when they change.

  module Translate

    # Turn a Ruby object into an SQL string.
    #
    # The conversion depends upon the type of thing:
    #
    # [[String, ...]] 
    #   An arbitrary expression, possibly with value substitution.
    #   Converted by calling #substitute_values
    #
    #   Examples:
    #     ['foo'] -> 'foo'
    #     ['%s + %s', 1, 1.414] -> '1 + 1.414'
    #
    # [[:in, ...]]
    #   A list of values that will be converted by recursively
    #   calling escape_sql, separated with commas, and surrounded
    #   by parentheses.
    #
    #  Examples:
    #    [:in, 1, 2] -> "(1, 2)"
    #    [:in, 'foo', 'bar'] => "('foo', 'bar')"
    #
    # [String] 
    #   Backslashes and single-quotes are escaped; the resulting
    #   string is then enclosed in single-quotes.
    #   
    #   Examples:
    #     "foo" -> "'foo'"
    #     "fool's gold' -> %q"'fool\\'s gold'"
    #     'foo\\bar' -> %q"'foo\\\\bar'"
    #     
    # [false]
    #   Converted to "false"
    #
    # [true]
    #   Converted to "true"
    #
    # [Integer]
    #   Converted to a string
    #
    #   Examples:
    #     123 -> "123"
    #     -2 -> "-2"
    #
    # [BigDecimal]
    #   Converted ot a a string
    # 
    #   Examples:
    #     BigDecimal("123.456789012345") -> "123.456789012345"
    #
    # [Float]
    #   Converted to a string with 15 digits of precision, using exponential
    #   notation of necessary.
    #
    #   Examples:
    #     0 -> "0"
    #     -1 -> "-1"
    #     3.1415926535898 -> "3.1415926535898"
    #     1e100 -> "1e+100"
    #
    # [Time]
    #   Converted to a timestamp with microseconds.
    #
    #   Examples:
    #     Time.local(2000, 1, 2, 3, 4, 5, 6) -> 
    #       "timestamp '2000-01-02 03:04:05.000006'"
    #
    # [:default]
    #   Converted to "default"
    #
    # [nil]
    #   Converted to "null"
    #
    # [Select]
    #   The statement method is called to get the SQL, which is then
    #   wrapped in parentheses.
    #
    #   Example, supposing that select.statement is "select 1 as i":
    #     select -> "(select 1 as i)"
    #
    # [anything else]
    #   Treated as a String (after calling to_s on it)

    def escape_sql(thing)
      return "null" if thing.nil?
      if thing.is_a?(Array)
        substitute_values(thing)
      elsif thing.respond_to?(:to_sql)
        thing.to_sql
      elsif thing.is_a?(Time)
        "timestamp '#{timeToSql(thing)}'"
      elsif thing.is_a?(DateTime)
        "timestamp with time zone '#{datetime_to_sql(thing)}'"
      elsif thing.is_a?(Integer)
        thing.to_s
      elsif thing.is_a?(Float)
        "%.14g" % thing
      elsif thing.is_a?(Date)
        "date '#{thing}'"
      elsif thing.is_a?(BigDecimal)
        thing.to_s('f')
      elsif thing == false
        "false"
      elsif thing == true
        "true"
      elsif thing == :default
        "default"
      elsif thing.respond_to?(:statement)
        "(#{thing.statement})"
      else
        string_to_sql(thing.to_s, '\\')
      end
    end
    module_function :escape_sql

    # Convert an arbitrary expression to SQL, possibly with value
    # substitution.  expression is an array.  
    #
    # If the first element of the array is a String, then it is the
    # format specificer The format specifier contains a %s for each
    # value.  The remainin items, if they exist, are values.  Each
    # value is turned into a string by calling escape_sql and is then
    # substituted for a %s in the format specifier.  
    #
    # If the first element of the array is :in, then the remaining
    # items are to be formatted using escape_sql, separated by commas,
    # and surrounded by parentheses.
    #
    # Examples:
    #** example: translate_substitute_values
    #   p Translate.substitute_values(['foo'])                 # "foo"
    #   p Translate.substitute_values(['%s + %s', 1, 2])       # "1 + 2"
    #   p Translate.substitute_values([:in, 1, 2])             # "(1, 2)"
    #   p Translate.substitute_values([:in, 'foo', 'bar'])     # "('foo', 
    #                                                          # 'bar')"
    #**

    def substitute_values(expression)
      if expression.is_a?(Array)
        pieces = expression[1..-1].collect do |value|
          escape_sql(value)
        end
        if expression.first == :in
          "(#{pieces.join(', ')})"
        else
          expression[0] % pieces
        end
      else
        expression
      end
    end
    module_function :substitute_values

    # Escape an array to be inserted into a Postgres array column.
    # Array columns are a Postgres extension.

    def escape_array(a)
      if a.is_a?(Array)
        if a.empty?
          "'{}'"
        else
          pieces = a.collect do |e|
            escape_array(e)
          end
          "ARRAY[#{pieces.join(', ')}]"
        end
      else
        escape_sql(a)
      end
    end
    module_function :escape_array

    # Escape an array to be inserted into a Posgres bytea[] column.
    # Array columns (and bytea columns) are a Postgres extension.

    def escape_bytea_array(a)
      escape_bytea_quote(a) do |e|
        e.
          gsub(/\\/, '\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\').
          gsub(/\000/, "\\\\\\\\\\\\\\\\000")
      end
    end
    module_function :escape_bytea_array

    def escape_bytea_quote(a, &escaper)
      return "null" if a.nil?
      "'#{escape_array_noquote(a, &escaper)}'"
    end
    module_function :escape_bytea_quote
    private_class_method :escape_bytea_quote

    def escape_array_noquote(a, &escaper)
      pieces = a.collect do |e|
        if e.is_a?(Array)
          escape_array_noquote(e, &escaper)
        else
          escaped = escaper.call(e.to_s).
            gsub(/'/, "\\\\'").
            gsub(/"/, "\\\\\\\"")
          '"' + escaped + '"'
        end
      end
      "{" + pieces.join(',') + "}"
    end
    module_function :escape_array_noquote
    private_class_method :escape_array_noquote

    # Translate a Postgres string representation of an array into a
    # Ruby array of strings.

    def sql_to_array(s)
      begin
        a, t = sql_to_array2(s)
        raise ArgumentError unless t.empty?
        a
      rescue ArgumentError
        raise ArgumentError, s.inspect
      end
    end
    module_function :sql_to_array

    def sql_to_array2(s)
      if s !~ /\A\{/m
        raise ArgumentError
      else
        t = $'
        a = []
        loop do
          case t
          when /\A\},?/
            return [a, $']
          when /\A\{/
            e, t = sql_to_array2(t)
            a << e
          when /\A([^"][^\},]*),?/m
            t = $' || ""
            a << $1
          when /\A"((?:[^\\]|\\\\|\\")*?)",?/m
            t = $' || ""
            a << $1.gsub(/\\\\/, "\\").gsub(/\\"/, '"')
          else
            raise ArgumentError
          end
        end
        a
      end
    end
    module_function :sql_to_array2
    private_class_method :sql_to_array2

    # Escape a string to be inserted into a bytea (byte array) column.
    #
    # [s]
    #   The value to convert.  Should be one of:
    #   * String
    #   * nil
    #   * :default
    #
    # The following characters get converted to mega-backslashed octal:
    #   \x00-\x1f
    #   '
    #   \ 
    #   \x7f-\xff

    def escape_bytea(s)
      return "null" if s.nil?
      return "default" if s == :default
      "'" + PGconn.escape_bytea(s) + "'"
    end
    module_function :escape_bytea

    # Unescape octal escape sequences, turning them back into bytes.

    def unescape_octal_escapes(s)
      s.gsub(/\\(\d{3})/) do
        $1.oct.chr
      end.gsub(/\\\\/, '\\')
    end
    module_function :unescape_octal_escapes

    # Unescape a bytea string read from postgres.

    def unescape_bytea(s)
      s.gsub(/\\(\\|[0-3][0-7][0-7])/) do
        if $1 == "\\"
          "\\"
        else
          $1.oct.chr
        end
      end
    end
    module_function :unescape_bytea

    # Unescape a text string read from postges.

    def unescape_text(s)
      unescape_bytea(s)
    end
    module_function :unescape_text

    # Convert a time to SQL format, including microseconds:
    # (YYYY-mm-dd HH:MM:SS.uuuuuu)

    def timeToSql(time)
      time.strftime("%Y-%m-%d %H:%M:%S.") + ("%06d" % time.usec)
    end
    module_function :timeToSql

    # Convert a datetime to Postgres format (ie "2003-10-18
    # 11:30:24.000000-07")

    def datetime_to_sql(d)
      d.strftime("%Y-%m-%d %H:%M:%S%z").gsub(/Z$/, "+0000")
    end
    module_function :datetime_to_sql

    # Convert a date from Postgres format (ie "2003-10-18") to a Date

    def sql_to_date(s)
      Date.parse(s)
    end
    module_function :sql_to_date

    # Convert a time with timezone from Postgres format (ie
    # "2003-10-18 11:30:24-07") to a DateTime.

    def sql_to_datetime(s)
      DateTime.parse(s)
    end
    module_function :sql_to_datetime

    # Escape a "char" type (the special Postgres internal type used in
    # system tables).
    #
    # [s]
    #   A String of length 1.

    def escape_qchar(s)
      if s.nil?
        "null"
      else
        "'" + escape_char(s[0]) + "'"
      end
    end
    module_function :escape_qchar

#     # Escape a "char"[] type (the special Postgres internal type used
#     # in system tables).
#     #
#     # [a]
#     #   An array (possibly nested) of String of length 1.

#     def escape_qchar_array(a)
#       escape_bytea_array(a)
#     end
#     module_function :escape_qchar_array

    # Unescape a "char" type.  This is a special internal type (yes, the
    # quotes are part of the type name).
    #
    # [s]
    #   A String of length 1.  If empty, it really means "\000".

    def unescape_qchar(s)
      if s.empty?
        "\000"
      else
        return s
      end
    end
    module_function :unescape_qchar

    # Escape a character, converting non-printable (0x0-0x1f, 0x7f-0xff),
    # backslash, and single-quote into an octal escape sequence.
    #
    # [c]
    #   The character code to convert (an integer between 0 and 255)
    #
    # [backslahes]
    #   The backslashes to use in the escape sequence

    def escape_char(c, backslashes = '\\')
      "#{backslashes}%03o" % c
    end
    module_function :escape_char
    private_class_method :escape_char

    # Escape a string, converting non-printable (\x0-\x1f, \x7f-\xff),
    # backshlash, and single-quote into octal escape sequences and/or
    # unicode.
    #
    # [thing]
    #   The string to convert
    #
    # [backslashes]
    #   The backslashes to use in the escape sequence.

    def string_to_sql(thing, backslashes)
      "E'" + thing.gsub(/[\x0-\x1f\x80-\xff'\\]/) do |c|
        escape_char(c[0], backslashes)
      end + "'"
    end
    module_function :string_to_sql
    private_class_method :string_to_sql

    def deep_collect(a)
      if a.is_a?(Array)
        a.collect do |e|
          deep_collect(e) do |v| yield(v) end
        end
      else
        yield(a)
      end
    end
    module_function :deep_collect

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
