#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'

class TranslateTest < Test

  include SqlPostgres
  include TestUtil

  def testEscapeSql
    pi = 3.1415926535897932384626433832795028841971693993751058209749445923
    testCases = [
      [nil, 'null'],
      ["", "E''"],
      ["foo", %q"E'foo'"],
      ["fred's", %q"E'fred\\047s'"],
      ['\\', %q"E'\\134'"],
      [Time.local(2000, 1, 2, 3, 4, 5, 6), 
        "timestamp '2000-01-02 03:04:05.000006'"],
      [Time.local(1999, 12, 31, 23, 59, 59, 999999), 
        "timestamp '1999-12-31 23:59:59.999999'"],
      [1, '1'],
      [-1, '-1'],
      [1.0, "1"],
      [-1.0, "-1"],
      [pi, "3.1415926535898"],
      [-pi, "-3.1415926535898"],
      [1e100, "1e+100"],
      [-1e-100, "-1e-100"],
      [true, "true"],
      [false, "false"],
      [:default, "default"],
      [['1 + %s', 1], '1 + 1'],
      [[:in, 1, 2], '(1, 2)'],
      [[:in, 'foo', 'bar'], "(E'foo', E'bar')"],
      [BigDecimal('0'), '0.0'],
      [BigDecimal('0.'), '0.0'],
      [BigDecimal('1234567890.0987654321'), '1234567890.0987654321'],
      [BigDecimal('0.000000000000000000000000000001'), '0.000000000000000000000000000001'],
      [PgTime.new(0, 0, 0), "time '00:00:00'"],
      [PgTime.new(23, 59, 59), "time '23:59:59'"],
      [
        PgTimeWithTimeZone.new,
        "time with time zone '00:00:00+00:00'"
      ],
      [
        PgTimeWithTimeZone.new(12, 0, 0, -8), 
        "time with time zone '12:00:00-08:00'"
      ],
      [
        PgTimeWithTimeZone.new(23, 59, 59, 8), 
        "time with time zone '23:59:59+08:00'"
      ],
      [
        DateTime.civil(2001, 1, 1, 0, 0, 0, Rational(7, 24)),
        "timestamp with time zone '2001-01-01 00:00:00+0700'",
      ],
      [Date.civil(2001, 1, 1), "date '2001-01-01'"],
      [
        PgTimestamp.new(2001, 1, 2, 12, 0, 1),
        "timestamp '2001-01-02 12:00:01.00000'"
      ],
      [PgInterval.new('hours'=>1), "interval '01:00'"],
      [PgInterval.new('days'=>1), "interval '1 day'"],
      [PgPoint.new(1, 2), "point '(1, 2)'"],
      [PgPoint.new(3, 4), "point '(3, 4)'"],
      [
        PgLineSegment.new(PgPoint.new(1, 2), PgPoint.new(3, 4)), 
        "lseg '((1, 2), (3, 4))'"
      ],
      [
        PgBox.new(PgPoint.new(1, 2), PgPoint.new(3, 4)), 
        "box '((1, 2), (3, 4))'"
      ],
      [
        PgPath.new(true, PgPoint.new(1, 2), PgPoint.new(3, 4)), 
        "path '((1, 2), (3, 4))'"
      ],
      [
        PgPolygon.new(PgPoint.new(1, 2), PgPoint.new(3, 4)), 
        "polygon '((1, 2), (3, 4))'"
      ],
      [["%s %s", 1, 'Fred'], "1 E'Fred'"],
    ]
    for testCase in testCases
      assertInfo("For test case #{testCase.inspect}") do
        raw, escaped = *testCase
        assertEquals(Translate.escape_sql(raw), escaped)
      end
    end
  end

  def test_escape_array
    testCases = [
      [nil, "null"],
      [[], %q"'{}'"],
      [[1], %q"ARRAY[1]"],
      [[1, 2], %q"ARRAY[1, 2]"],
      [['foo'], %q"ARRAY[E'foo']"],
      [['\\'], %q"ARRAY[E'\\134']"],
      [["a,b,c"], %q"ARRAY[E'a,b,c']"],
      [["a", "b", "c"], %q"ARRAY[E'a', E'b', E'c']"],
      [["\"Hello\""], %q"ARRAY[E'\"Hello\"']"],
      [
        [[0, 0], [0, 1], [1, 0], [1, 1]],
        "ARRAY[ARRAY[0, 0], ARRAY[0, 1], ARRAY[1, 0], ARRAY[1, 1]]"
      ],
    ]
    for array, escaped in testCases
      assertInfo("For array #{array.inspect}") do
        assertEquals(Translate.escape_array(array), escaped)
      end
    end
  end

  def test_escape_bytea_array
    testCases = [
      [[], "'{}'"],
      [["", "foo"], "'{\"\",\"foo\"}'"],
      ["\000\037 ", "'{\"\\\\\\\\000\037 \"}'"],
      [["'\\"], "'{\"\\'\\\\\\\\\\\\\\\\\"}'"],
      [["~\177\377"], "'{\"~\177\377\"}'"],
      [["\""], "'{\"\\\\\"\"}'"],
      [nil, "null"],
    ]
    for array, escaped in testCases
      assertInfo("For array #{array.inspect}") do
        assertEquals(Translate.escape_bytea_array(array), escaped)
      end
    end
  end

  def test_sql_to_array
    goodTestCases = [
      ["{}", []],
      ["{foo}", ["foo"]],
      ["{foo,bar,\"fool's gold\"}", ["foo", "bar", "fool's gold"]],
      ["{\"\\\\\"}", ["\\"]],
      ["{\"\\\\\",fool's}", ["\\", "fool's"]],
      ["{\"a,b,c\"}", ["a,b,c"]],
      ["{\"\\\"Hello!\\\"\"}", ["\"Hello!\""]],
      ["{\"\001\n\037\"}", ["\001\n\037"]],
      [
        "{{f,f},{f,t},{t,f},{t,t}}", 
        [["f", "f"], ["f", "t"], ["t", "f"], ["t", "t"]],
      ],
    ]
    for sql, array in goodTestCases
      assertInfo("For sql #{sql.inspect}") do
        assertEquals(Translate.sql_to_array(sql), array)
      end
    end
    badTestCases = [
      "",
      "{",
      "{foo",
      "{foo}x",
    ]
    for sql in badTestCases
      assertInfo("For sql #{sql.inspect}") do
        assertException(ArgumentError, sql.inspect) do
          Translate.sql_to_array(sql)
        end
      end
    end
  end

  def test_escape_qchar
    test_cases = [
      [nil, 'null'],
      ["\000", %q"E'\\000'"],
      ["\001", %q"E'\\001'"],
      ["\377", %q"E'\\377'"],
      ["a", "E'\\141'"],
    ]
    for raw, escaped in test_cases
      assertInfo("For raw=#{raw.inspect}") do
        assertEquals(Translate.escape_qchar(raw), escaped)
      end
    end
  end

  def test_escape_bytea
    testCases = [
      [nil, 'null'],
      [:default, "default"],
      ["", "E''"],
      ["foo", %q"E'foo'"],
      ["\000\037 ", %q"E'\\\\000\\\\037 '"],
      ["'\\", %q"E'''\\\\\\\\'"],
      ["~\177\377", "E'~\\\\177\\\\377'"],
    ]
    for testCase in testCases
      assertInfo("For test case #{testCase.inspect}") do
        raw, escaped = *testCase
        assertEquals(Translate.escape_bytea(raw), escaped)
      end
    end
  end

  def test_unescape_bytea
    testCases = [
      ["", ""],
      ["abc", "abc"],
      ["\\\\", "\\"],
      ["\\001", "\001"],
      ["\\037", "\037"],
      ["\\177", "\177"],
      ["\\200", "\200"],
      ["\\377", "\377"],
      ["\\477", "\\477"],
      ["\\387", "\\387"],
      ["\\378", "\\378"],
      ["\\n", "\\n"],
      ["abc\\", "abc\\"],
    ]
    for testCase in testCases
      assertInfo("For test case #{testCase.inspect}") do
        escaped, raw = *testCase
        assertEquals(Translate.unescape_bytea(escaped), raw)
      end
    end
  end

  def test_unescape_qchar
    testCases = [
      ["", "\000"],
      ["\001", "\001"],
      ["\037", "\037"],
      [" ", " "],
      ["~", '~'],
      ["\277", "\277"],
      ["\300", "\300"],
      ["\377", "\377"],
    ]
    for testCase in testCases
      assertInfo("For test case #{testCase.inspect}") do
        escaped, raw = *testCase
        assertEquals(Translate.unescape_qchar(escaped), raw)
      end
    end
  end

  def testEscapeSql_Select
    select = Object.new
    def select.statement
      "foo"
    end
    assertEquals(Translate.escape_sql(select), "(foo)")
  end

  def testEscapeSql_AllCharValues
    tableName = testTableName("foo")
    Connection.open do |connection|
      connection.exec("begin transaction;")
      connection.exec("create temporary table #{tableName} "\
                      "(i int, t text);")
      range = (1..255)
      for i in range
        assertInfo("For i=#{i.inspect}") do
          statement = ("insert into #{tableName} (i, t) "\
                       "values (#{i}, #{Translate.escape_sql(i.chr)});")
          connection.query(statement)
        end
      end
      connection.exec("end transaction;")
      statement = "select i, t, length(t) from #{tableName} order by i;"
      rows = connection.query(statement)
      for i in range
        assertInfo("for i = #{i}") do
          row = rows.assoc(i.to_s)
          char_number, text, length = *row
          assertEquals(length.to_i, 1)
          c = Translate.unescape_text(text)
          assertEquals(c, i.chr)
        end
      end
    end
  end

  def testSubstituteValues
    assertEquals(Translate.substitute_values("foo"), "foo")
    assertEquals(Translate.substitute_values(["bar %s", 1]), "bar 1")
    assertEquals(Translate.substitute_values(["bar %s", "O'Malley"]), 
                 "bar E'O\\047Malley'")
    assertEquals(Translate.substitute_values(["%s %s", nil, 1.23]), "null 1.23")
  end

  def test_sql_to_datetime
    testCases = [
      [2003, 10, 18, 11, 30, 24, -7],
      [2001, 1, 1, 0, 0, 0, 0],
      [1970, 12, 31, 23, 59, 59, -11],
    ]
    for testCase in testCases
      sql = "%04d-%02d-%02d %02d:%02d:%02d%+03d" % testCase
      dateTime = DateTime.civil(*testCase[0..5] + 
                                [Rational(testCase[6], 24)])
      assertEquals(Translate.sql_to_datetime(sql), dateTime)
    end
  end

  def test_datetime_to_sql
    testCases = [
      [2003, 10, 18, 11, 30, 24, -7],
      [2001, 1, 1, 0, 0, 0, 0],
      [1970, 12, 31, 23, 59, 59, -11],
    ]
    for testCase in testCases
      sql = "%04d-%02d-%02d %02d:%02d:%02d%+03d00" % testCase
      dateTime = DateTime.civil(*testCase[0..5] + 
                                [Rational(testCase[6], 24)])
      assertEquals(Translate.datetime_to_sql(dateTime), sql)
    end
  end

  def test_sql_to_date
    testCases = [
      [2000, 1, 1],
      [1899, 12, 31],
    ]
    for testCase in testCases
      sql = "%04d-%02d-%02d" % testCase
      date = Date.civil(*testCase)
      assertEquals(Translate.sql_to_date(sql), date)
    end
  end

  def test_deep_collect
    testCases = [
      ["1", 1],
      [[], []],
      [["1"], [1]],
      [["1", "2"], [1, 2]],
      [["1", ["2", "3"], []], [1, [2, 3], []]],
    ]
    for testCase in testCases
      a, result = *testCase
      assertEquals(Translate.deep_collect(a) do |e| e.to_i end, result)
    end
  end

end

TranslateTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
