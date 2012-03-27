#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'bigdecimal'
require 'date'

# Test putting stuff in using Insert and getting it back out using
# Select.

class RoundTripTest < Test

  include SqlPostgres
  include TestUtil

  def test
    testCases = [
      [ 
        ["integer", "int", "int4"], 
        [-2147483648, +2147483647, nil]
      ],
      [
        ["smallint", "int2"], 
        [-32768, +32767, nil]
      ],
      [
        [
          "smallint[]", "int2[]",
          "integer[]", "int[]", "int4[]", 
          "bigint[]", "int8[]",
        ],
        [[], [1], [1, 2], [-1, 0, 1], [[1, 2], [3, 4]], [[1, 2], [3, 4]], nil],
      ],
      [
        ["bigint", "int8"], 
        [-9223372036854775808, +9223372036854775807, nil]
      ],
      [
        ["real", "float4"], 
        [-1e30, -3.14159, +3.14159, 1e30, nil]
      ],
      [
        ["real[]", "float4[]"],
        [
          [[-1e30, -3.14159], [+3.14159, 1e30]], 
          nil
        ]
      ],
      [
        ["decimal (7, 6)", "numeric (7, 6)"], 
        [BigDecimal("-3.14159"), BigDecimal("+3.14159"), nil]
      ],
      [
        ["double precision", "float8"],
        [-1e290, -3.1415926535897, +3.1415926535897, 1e290, nil]
      ],
      [
        ["double precision[]", "float8[]"],
        [
          [[-1e290, -3.1415926535897], [+3.1415926535897, 1e290]],
          nil
        ]
      ],
      [
        ["serial", "serial4"],
        [1, +2147483647]
      ],
      [
        ["bigserial", "serial8"],
        [1, +9223372036854775807]
      ],
      [
        ["text", "varchar(255)", "character varying (255)"], 
        [
          "",
          "Fool's gold",
          allCharacters(1),
          nil
        ]
      ],
      [
        ["text[]", "varchar(255)[]", "character varying(255)[]"],
        [
          [], ["foo"], ["foo", "bar", "fool's gold"], 
          ["\\", "fool's", "a,b,c", "{}", "\"Hello!\"", "\001"],
          # Can't get this character arrays to work with the full
          # suite of characters, but we don't use character arrays
          # anyhow.
          # [allCharacters(1)],
          [["a", "b"], ["c", "d"]],
          nil,
        ]
      ],
      [
        ["character(4)", "char(4)"],
        ["foo ", "'\"\001 ", nil]
      ],
      [
        ["character(4)[]", "char(4)[]"],
        [
          [["foo ", "'\"\001 "], ["    ", " a b"]], 
          nil
        ]
      ],
      [
        ["character", "char"],
        ["a", "\001", "'", '"', nil]
      ],
      [
        ["character[]", "char[]"],
        [["a", "b"], ["c", "d"]],
        nil
      ],
      [
        ['"char"'],
        ["\001", "\037", " ", "~", "\127", "\130", "\277", "\300", "\377"],
      ],
      [
        ["name"],
        ["foo", nil]
      ],
      [
        ["name[]"],
        [
          [["foo", "bar"], ["baz", "quux"]],
          nil
        ]
      ],
      [
        ["bytea"],
        [
          "", 
          allCharacters, 
          nil,
          "\xc1\xb7",
           "\\123",
          "\\668G\345\256L\245",
        ],
      ],
      # Can't get this to work, but we don't use byte array arrays anyhow.
      # [
      #  ["bytea[]"],
      #  [
      #    [["foo", "bar"], ["baz", "quux"]],
      #    ["\\", "\000", allCharacters],
      #    nil
      #  ]
      # ],
      [
        ["timestamp", "timestamp without time zone"],
        [
          PgTimestamp.new(1900, 1, 1, 0, 0, 0),
          PgTimestamp.new(1999, 12, 31, 23, 59, 59),
          nil
        ]
      ],
      [
        ["timestamp[]", "timestamp without time zone[]"],
        [
          [
            PgTimestamp.new(1900, 1, 1, 0, 0, 0),
            PgTimestamp.new(1999, 12, 31, 23, 59, 59)
          ],
          nil
        ]
      ],
      [
        ["timestamp with time zone"],
        [
          {
            'in'=>DateTime.civil(2001, 1, 1, 0, 0, 0, Rational(7, 24)),
            'out'=>DateTime.civil(2000, 12, 31, 10, 0, 0, Rational(-7, 24)),
          },
          DateTime.civil(1900, 12, 31, 23, 59, 59, Rational(0, 24)),
          nil
        ]
      ],
      [
        ["timestamp with time zone[]"],
        [
          [
            DateTime.civil(2001, 1, 1, 0, 0, 0, Rational(7, 24)),
            DateTime.civil(1900, 12, 31, 23, 59, 59, Rational(0, 24)),
          ],
          nil
        ]
      ],
      [
        ["interval"],
        [
          PgInterval.new,
          PgInterval.new('seconds'=>1),
          PgInterval.new('minutes'=>1),
          PgInterval.new('hours'=>1),
          PgInterval.new('days'=>1),
          PgInterval.new('days'=>2),
          {
            'in'=>PgInterval.new('weeks'=>1), 
            'out'=>PgInterval.new('days'=>7),
          },
          PgInterval.new('months'=>1),
          PgInterval.new('months'=>2),
          PgInterval.new('years'=>1),
          PgInterval.new('years'=>2),
          {
            'in'=>PgInterval.new('decades'=>1), 
            'out'=>PgInterval.new('years'=>10),
          },
          {
            'in'=>PgInterval.new('centuries'=>1), 
            'out'=>PgInterval.new('years'=>100),
          },
          {
            'in'=>PgInterval.new('millennia'=>1), 
            'out'=>PgInterval.new('years'=>1000),
          },
          {
            'in'=>PgInterval.new('millennia'=>1, 'centuries'=>2, 'decades'=>3, 
                                 'years'=>4, 'months'=>5, 'weeks'=>6, 
                                 'days'=>7, 'hours'=>8, 'minutes'=>9, 
                                 'seconds'=>10),
            'out'=>PgInterval.new('years'=>1234, 'months'=>5, 'days'=>49, 
                                  'hours'=>8, 'minutes'=>9, 'seconds'=>10),
          },
          PgInterval.new('days'=>-1),
          {
            'in'=>PgInterval.new('days'=>1, 'ago'=>true), 
            'out'=>PgInterval.new('days'=>-1),
          },
          {
            'in'=>PgInterval.new('days'=>-1, 'ago'=>true), 
            'out'=>PgInterval.new('days'=>1),
          },
          PgInterval.new('seconds'=>1.1),
          {
            'in'=>PgInterval.new('hours'=>1, 'minutes'=>-1, 'seconds'=>1),
            'out'=>PgInterval.new('hours'=>0, 'minutes'=>59, 'seconds'=>1),
          },
          nil
        ]
      ],
      [
        ["interval[]"],
        [
          [
            [
              PgInterval.new('days'=>1),
              PgInterval.new('hours'=>2),
            ],
            [
              PgInterval.new('minutes'=>3),
              PgInterval.new('seconds'=>4),
            ],
          ],
          nil,
        ]
      ],
      [
        ["date"],
        [Date.civil(2001, 1, 1), Date.civil(1900, 12, 31), nil]
      ],
      [
        ["date[]"],
        [[Date.civil(2001, 1, 1), Date.civil(1900, 12, 31)], nil]
      ],
      [
        ["time"],
        [PgTime.new(0, 0, 0), PgTime.new(23, 59, 59), nil]
      ],
      [
        ["time[]"],
        [[PgTime.new(0, 0, 0), PgTime.new(23, 59, 59)], nil]
      ],
      [
        ["time with time zone"],
        [
          PgTimeWithTimeZone.new(0, 0, 0, 0, 0),
          PgTimeWithTimeZone.new(12, 0, 0, 0, 30),
          PgTimeWithTimeZone.new(12, 0, 0, -8, 0),
          PgTimeWithTimeZone.new(23, 59, 59, +8, 0),
          nil
        ]
      ],
      [
        ["time with time zone[]"],
        [
          [
            PgTimeWithTimeZone.new(0, 0, 0, 0, 0),
            PgTimeWithTimeZone.new(23, 59, 59, +8, 0),
          ],
          nil
        ]
      ],
      [
        ["boolean"],
        [false, true, nil],
      ],
      [
        ["boolean[]"],
        [
          [false, true],
          [[false, false], [false, true], [true, false], [true, true]],
          nil,
        ]
      ],
      [
        ["point"],
        [
          PgPoint.new(0, 0), 
          PgPoint.new(1.2, -3), 
          PgPoint.new(1e20, -1e20),
          nil,
        ],
      ],
      [
        ["point[]"],
        [ 
          [PgPoint.new(0, 0), PgPoint.new(1.2, -3), PgPoint.new(1e20, -1e20)],
          nil,
        ],
      ],
      [
        ["lseg"],
        [
          PgLineSegment.new(0, 0, 0, 0),
          PgLineSegment.new(1.2, -2, 1e10, -1e10),
          nil
        ]
      ],
      [
        ["lseg[]"],
        [
          [
            PgLineSegment.new(0, 0, 0, 0),
            PgLineSegment.new(1.2, -2, 1e10, -1e10),
          ],
          nil
        ]
      ],
      [
        ["box"],
        [
          PgBox.new(0, 0, 0, 0),
          PgBox.new(1e10, -2, 1.2, -1e10),
          nil
        ]
      ],
      # Can't get this to work, but we don't use box arrays anyhow.
      # [
      #  ["box[]"],
      #  [
      #    [
      #      PgBox.new(0, 0, 0, 0),
      #      PgBox.new(1.2, -2, 1e10, -1e10),
      #    ],
      #    nil
      #  ]
      # ],
      [
        ["path"],
        [
          PgPath.new(false, PgPoint.new(1, 2)),
          PgPath.new(true, PgPoint.new(1, 2), PgPoint.new(3, 4)),
          nil,
        ]
      ],
      [
        ["path[]"],
        [
          [
            PgPath.new(false, PgPoint.new(1, 2)),
            PgPath.new(true, PgPoint.new(1, 2), PgPoint.new(3, 4)),
          ],
          nil
        ]
      ],
      [
        ["polygon"],
        [
          PgPolygon.new(PgPoint.new(1, 2)),
          PgPolygon.new(PgPoint.new(1, 2), PgPoint.new(3, 4)),
          nil,
        ]
      ],
      [
        ["polygon[]"],
        [
          [
            PgPolygon.new(PgPoint.new(1, 2)),
            PgPolygon.new(PgPoint.new(1, 2), PgPoint.new(3, 4)),
          ],
          nil
        ]
      ],
      [
        ["circle"],
        [
          PgCircle.new(0, 0, 0),
          PgCircle.new(1, 2, 3),
          nil,
        ]
      ],
      [
        ["circle[]"],
        [
          [
            PgCircle.new(0, 0, 0),
            PgCircle.new(1, 2, 3),
          ],
          nil,
        ]
      ],
      [
        ["bit varying", "bit varying(6)"],
        [
          PgBit.new,
          PgBit.new("0"),
          PgBit.new("010101"),
          nil
        ]
      ],
      [
        ["bit varying[]", "bit varying(6)[]"],
        [
          [
            PgBit.new,
            PgBit.new("0"),
            PgBit.new("010101"),
          ],
          nil
        ]
      ],
      [
        ["bit(1)", "bit"],
        [
          PgBit.new("1"),
          PgBit.new("0"),
          nil
        ]
      ],
      [
        ["bit(1)[]", "bit[]"],
        [
          [
            PgBit.new("1"),
            PgBit.new("0"),
          ],
          nil
        ]
      ],
      [
        ["inet"],
        [
          PgInet.new("0.0.0.0/0"),
          {
            'in'=>PgInet.new("255.255.255.255/32"), 
            'out'=>PgInet.new("255.255.255.255"),
          },
          PgInet.new("255.255.255.255"), 
          PgInet.new("1.2.0.0/16"),
          nil
        ],
      ],
      [
        ["inet[]"],
        [
          [
            PgInet.new("255.255.255.255"), 
            PgInet.new("1.2.0.0/16")
          ],
          nil,
        ],
      ],
      [
        ["cidr"],
        [
          PgCidr.new("0.0.0.0/0"),
          PgCidr.new("255.255.255.255/32"), 
          PgCidr.new("1.2.0.0/16"),
          nil,
        ],
      ],
      [
        ["cidr[]"],
        [
          [
            PgCidr.new("0.0.0.0/0"), 
            PgCidr.new("255.255.255.255/32")
          ],
          nil,
        ],
      ],
      [
        ["macaddr"],
        [
          PgMacAddr.new("08:00:2b:01:02:03"),
          PgMacAddr.new("00:00:00:00:00:00"),
          nil,
        ]
      ],
      [
        ["macaddr[]"],
        [
          [
            PgMacAddr.new("08:00:2b:01:02:03"),
            PgMacAddr.new("00:00:00:00:00:00"),
          ],
          nil,
        ]
      ],
    ]
    makeTestConnection do |connection|
      connection.exec("set client_min_messages = 'warning'")
      for testCase in testCases
        columnTypes, values = *testCase
        for columnType in columnTypes
          assertInfo("For column type #{columnType}") do
            connection.exec("create temporary table #{table1} "\
                            "(v #{columnType})")
            for value in values
              assertInfo("For value #{value.inspect}") do
                if value.is_a?(Hash)
                  value_in = value['in']
                  value_out = value['out']
                else
                  value_in = value
                  value_out = value
                end
                connection.exec("delete from #{table1}")
                insert = Insert.new(table1, connection)
                case columnType
                when 'bytea[]'
                  insert.insert_bytea_array('v', value_in)
                when /\[\]/
                  insert.insert_array('v', value_in)
                when '"char"'
                  insert.insert_qchar('v', value_in)
                when 'bytea'
                  insert.insert_bytea('v', value_in)
                else
                  insert.insert('v', value_in)
                end
                insert.exec
                select = Select.new(connection)
                select.select('v')
                select.from(table1)
                result = select.exec[0]['v']
                if result.respond_to?(:encoding)
                  result = result.force_encoding('ASCII-8BIT')
                end
                assertEquals(result, value_out)
              end
            end
            connection.exec("drop table #{table1}")
          end
        end
      end
    end
  end

end

RoundTripTest.new.run if $0 == __FILE__
