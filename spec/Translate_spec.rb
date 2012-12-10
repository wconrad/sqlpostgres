$: << File.dirname(__FILE__)
require 'spec_helper'

module SqlPostgres

  describe Translate do

    describe '::escape_sql' do

      def self.pi
        3.1415926535897932384626433832795028841971693993751058209749445923
      end

      def self.testCases
        [
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

      end

      testCases.each do |raw, escaped|

        context raw.inspect do

          it do
            Translate.escape_sql(raw).should == escaped
          end

        end
      end
    end

    describe '::test_escape_array' do

      def self.testCases
        [
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
      end

      testCases.each do |raw, escaped|

        context raw.inspect do

          it do
            Translate.escape_array(raw).should == escaped
          end

        end
      end
    end

    describe '::escape_bytea_array' do

      def self.testCases
        [
          [[], "'{}'"],
          [["", "foo"], "'{\"\",\"foo\"}'"],
          ["\000\037 ", "'{\"\\\\\\\\000\037 \"}'"],
          [["'\\"], "'{\"\\'\\\\\\\\\\\\\\\\\"}'"],
          [["~\177\377"], "'{\"~\177\377\"}'"],
          [["\""], "'{\"\\\\\"\"}'"],
          [nil, "null"],
        ]
      end

      testCases.each do |raw, escaped|

        context raw.inspect do

          it do
            Translate.escape_bytea_array(raw).should == escaped
          end

        end
      end

    end

    describe '::sql_to_array' do

      def self.goodTestCases
        [
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
      end

      def self.badTestCases
        [
          "",
          "{",
          "{foo",
          "{foo}x",
        ]
      end

      goodTestCases.each do |sql, array|

        context sql.inspect do

          it do
            Translate.sql_to_array(sql).should == array
          end

        end

      end

      badTestCases.each do |sql|

        context sql.inspect do

          it do
            expect do
              Translate.sql_to_array(sql).should == array
            end.to raise_error(ArgumentError, sql.inspect)
          end

        end

      end

    end

    describe '::test_escape_qchar' do

      def self.testCases
        [
          [nil, 'null'],
          ["\000", %q"E'\\000'"],
          ["\001", %q"E'\\001'"],
          ["\377", %q"E'\\377'"],
          ["a", "E'\\141'"],
        ]
      end

      testCases.each do |raw, escaped|

        context raw.inspect do

          it do
            Translate.escape_qchar(raw).should == escaped
          end

        end

      end

    end

    describe '::escape_bytea' do

      def self.testCases
        [
          [nil, 'null', 'null'],
          [:default, "default", "default"],
          ["", "''", "'\\x'"],
          ["foo", %q"'foo'", %q"'\\x666f6f'"],
          ["\000\037 ", %q"'\\000\\037 '", %q"'\\x001f20'"],
          ["'\\", %q"'''\\\\'", %q"'\\x275c'"],
          ["~\177\377", "'~\\177\\377'", "'\\x7e7fff'"],
        ]
      end

      testCases.each do |raw, escaped_84, escaped_90|

        test_connections.each do |test_context, test_connection|

          context test_context do

            context raw.inspect do

              let(:connection) {test_connection}

              it do
                pgconn = connection.pgconn
                escaped = if pgconn.server_version < 9_00_00
                            escaped_84
                          else
                            escaped_90
                          end
                if pgconn.server_version < 9_01_00
                  escaped = escaped.gsub("\\", "\\\\\\")
                  escaped = 'E' + escaped if raw.is_a?(String)
                end
                Translate.escape_bytea(raw, pgconn).should == escaped
              end
            end

          end

        end

      end

    end

    describe '::unescape_bytea' do

      def self.testCases
        [
          ["", ""],
          ["abc", "abc"],
          ["\\\\", "\\"],
          ["\\001", "\001"],
          ["\\x01", "\001"],
          ["\\037", "\037"],
          ["\\x1f", "\037"],
          ["\\177", "\177"],
          ["\\200", "\200"],
          ["\\377", "\377"],
          ["\\477", "477"], #DEBUG why had we been testing handling of badly escaped bytea would badly unescape???
          ["\\387", "387"],
          ["\\378", "378"],
          ["\\n", "n"],
          ["abc\\", "abc"],
          ["\\x779c", "w\234"]
        ]
      end

      testCases.each do |escaped, raw|

        test_connections.each do |test_context, test_connection|

          context test_context do

            context escaped.inspect do

              let(:connection) {test_connection}

              it do
                pgconn = connection.pgconn
                Translate.unescape_bytea(escaped, pgconn).should == raw
              end
            end
          end
        end
      end
    end

    describe '::unescape_qchar' do

      def self.testCases
        [
          ["", "\000"],
          ["\001", "\001"],
          ["\037", "\037"],
          [" ", " "],
          ["~", '~'],
          ["\277", "\277"],
          ["\300", "\300"],
          ["\377", "\377"],
        ]
      end

      testCases.each do |escaped, raw|

        context escaped do

          it do
            Translate.unescape_qchar(escaped).should == raw
          end

        end

      end

    end

    describe '::escapeSql' do

      context 'Select' do

        it do
          select = mock(Select, :statement => 'foo')
          Translate.escape_sql(select).should == "(foo)"
        end

      end

      context "AllCharValues" do

        RANGE = 1..255

        test_connections.each do |test_context, test_connection|

          context test_context do

            let(:connection) {test_connection}
            include_context('temporary table',
                            :table_name => 'escape_sql_test',
                            :columns => ['i int',
                              't text'
                            ])

            RANGE.each do |i|

              context "char: #{i}" do

                before(:each) do
                  insert = "insert into escape_sql_test (i, t) "\
                  "values (#{i}, #{Translate.escape_sql(i.chr)});"
                  connection.query(insert)
                  select = "select i, t, length(t) from escape_sql_test order by i;"
                  row = connection.query(select).first
                  @char_number, @text, @length = *row
                end

                it do
                  @length.should == '1'
                end

                it do
                  @text.should == i.chr
                end
              end

            end
          end

        end

      end

    end

    describe '::substitute_values' do

      def self.testCases
        [
          ["foo", "foo"],
          [["bar %s", 1], "bar 1"],
          [["bar %s", "O'Malley"], "bar E'O\\047Malley'"],
          [["%s %s", nil, 1.23], "null 1.23"],
        ]
      end

      testCases.each do |raw, expected|

        context raw do

          it do
            Translate.substitute_values(raw).should == expected
          end
        end

      end
    end

    describe 'datetime' do
      def self.testCases
        [
          [2003, 10, 18, 11, 30, 24, -7],
          [2001, 1, 1, 0, 0, 0, 0],
          [1970, 12, 31, 23, 59, 59, -11],
        ]
      end

      testCases.each do |time_parts|

        context time_parts.inspect do

          let(:sql) {"%04d-%02d-%02d %02d:%02d:%02d%+03d00" % time_parts}
          let(:dateTime) do
            DateTime.civil(*time_parts[0..5] +
                           [Rational(time_parts[6], 24)])
          end

          describe 'sql_to' do

            it do
              Translate.sql_to_datetime(sql).should == dateTime
            end

          end

          describe "to_sql" do

            it do
              Translate.datetime_to_sql(dateTime).should == sql
            end

          end

        end
      end
    end

    describe '::sql_to_date' do

      def self.testCases
        [
          [2000, 1, 1],
          [1899, 12, 31],
        ]
      end

      testCases.each do |time_parts|

        context time_parts.inspect do

          it do
            sql = "%04d-%02d-%02d" % time_parts
            date = Date.civil(*time_parts)
            Translate.sql_to_date(sql).should == date
          end

        end

      end
    end

    describe '::deep_collect' do
      def self.testCases
        [
          ["1", 1],
          [[], []],
          [["1"], [1]],
          [["1", "2"], [1, 2]],
          [["1", ["2", "3"], []], [1, [2, 3], []]],
        ]
      end

      testCases.each do |input, output|

        context input.inspect do

          it do
            Translate.deep_collect(input) do |e|
              e.to_i
            end.should == output
          end
        end
      end
    end

  end


end
