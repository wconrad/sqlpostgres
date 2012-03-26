#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgTimeWithTimeZoneTest < Test

  include SqlPostgres
  include RandomThings

  def test_ctor_defaults
    assertEquals(PgTimeWithTimeZone.new, 
                 PgTimeWithTimeZone.new(0, 0, 0, 0, 0))
  end

  def test_ctor_and_accessors
    hour = randomInteger
    minute = randomInteger
    second = randomInteger
    zone_hours = randomInteger
    zone_minutes = randomInteger
    time = PgTimeWithTimeZone.new(hour, minute, second, 
                                  zone_hours, zone_minutes)
    assertEquals(time.hour, hour)
    assertEquals(time.minute, minute)
    assertEquals(time.second, second)
    assertEquals(time.zone_hours, zone_hours)
    assertEquals(time.zone_minutes, zone_minutes)
  end

  def test_from_sql
    testCases = [
      ["12:00:00+00:30", [12, 0, 0, 0, 30]],
      ["00:00:00+08", [0, 0, 0, 8, 0]],
      ["00:00:00+08:30", [0, 0, 0, 8, 30]],
      ["23:59:59-08", [23, 59, 59, -8, 0]],
    ]
    for testCase in testCases
      sql, args = *testCase
      assertInfo("For sql #{sql.inspect}") do
        assertEquals(PgTimeWithTimeZone.from_sql(sql), 
                     PgTimeWithTimeZone.new(*args))
      end
    end
    assertException(ArgumentError, 'Invalid time with time zone: "foo"') do
      PgTimeWithTimeZone.from_sql("foo")
    end
  end

  def test_equality
    fields = ["hour", "minute", "second", "zone_hours", "zone_minutes"]
    for field in fields
      assertInfo("For field #{field}") do
        time1 = PgTimeWithTimeZone.new
        time2 = PgTimeWithTimeZone.new
        assertEquals(time1.eql?(time2), true)
        assertEquals(time1 == time2, true)
        assertEquals(time1 != time2, false)
        args = fields.collect do |f|
          if f == field then 1 else 0 end
        end
        time2 = PgTimeWithTimeZone.new(*args)
        assertEquals(time1 == time2, false)
        assertEquals(time1 != time2, true)
        assertEquals(time1.eql?(Object.new), false)
        assertEquals(time1 == Object.new, false)
      end
    end
  end

  def test_hash
    count = 0
    hashes = Hash.new(0)
    testHash = proc { |*args|
      assertEquals(PgTimeWithTimeZone.new(*args).hash, 
                   PgTimeWithTimeZone.new(*args).hash)
      hashes[PgTimeWithTimeZone.new(*args).hash] += 1
      count += 1
    }
    for i in (0...10)
      testHash.call(i, 0, 0, 0, 0)
      testHash.call(0, i, 0, 0, 0)
      testHash.call(0, 0, i, 0, 0)
      testHash.call(0, 0, 0, i, 0)
      testHash.call(0, 0, 0, 0, i)
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

  def test_to_s_and_to_sql
    testCases = [
      [[0, 0, 0, 0, 0], "00:00:00+00:00"],
      [[12, 0, 0, -8, 0], "12:00:00-08:00"],
      [[23, 59, 59, 23, 0], "23:59:59+23:00"],
    ]
    for testCase in testCases
      assertInfo("for test case #{testCase.inspect}") do
        args, expected = *testCase
        t = PgTimeWithTimeZone.new(*args)
        assertEquals(t.to_s, expected)
        assertEquals(t.to_sql, "time with time zone '#{t}'")
      end
    end
  end

end

PgTimeWithTimeZoneTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
