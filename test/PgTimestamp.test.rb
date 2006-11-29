#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgTimestampTest < Test

  include SqlPostgres
  include RandomThings

  def test_ctor_and_accessors
    fields = [:year, :month, :day, :hour, :minute, :second, :microseconds].collect do |field|
      [field, randomInteger]
    end
    timestamp = PgTimestamp.new(*fields.collect do |field, value| value end)
    for field, value in fields
      assertInfo("For field #{field}") do
        assertEquals(timestamp.send(field), value)
      end
    end
  end

  def test_ctor_defaults
    for number_of_args in (0..7)
      assertInfo("For number_of_args=#{number_of_args}") do
        assertEquals(PgTimestamp.new,
                     PgTimestamp.new(*([0] * number_of_args)))
      end
    end
  end

  def test_equality
    fields = ["year", "month", "day", "hour", "minute", "second", "microseconds"]
    for field in fields
      assertInfo("For field #{field}") do
        time1 = PgTimestamp.new
        time2 = PgTimestamp.new
        assertEquals(time1.eql?(time2), true)
        assertEquals(time1 == time2, true)
        assertEquals(time1 != time2, false)
        args = fields.collect do |f|
          if f == field then 1 else 0 end
        end
        time2 = PgTimestamp.new(*args)
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
      assertEquals(PgTimestamp.new(*args).hash, PgTimestamp.new(*args).hash)
      hashes[PgTimestamp.new(*args).hash] += 1
      count += 1
    }
    for i in (0...10)
      testHash.call(i, 0, 0, 0, 0, 0, 0)
      testHash.call(0, i, 0, 0, 0, 0, 0)
      testHash.call(0, 0, i, 0, 0, 0, 0)
      testHash.call(0, 0, 0, i, 0, 0, 0)
      testHash.call(0, 0, 0, 0, i, 0, 0)
      testHash.call(0, 0, 0, 0, 0, i, 0)
      testHash.call(0, 0, 0, 0, 0, 0, i)
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

  def test_to_s
    testCases = [
      [[0, 0, 0, 0, 0, 0], "0000-00-00 00:00:00.00000"],
      [[1999, 12, 31, 23, 59, 59], "1999-12-31 23:59:59.00000"],
      [[1999, 12, 31, 23, 59, 59, 98765], "1999-12-31 23:59:59.98765"],
    ]
    for testCase in testCases
      args, expected = *testCase
      assertEquals(PgTimestamp.new(*args).to_s, expected)
      assertEquals(PgTimestamp.new(*args).to_sql, "timestamp '#{expected}'")
    end
  end

  def test_to_local_time
    testCases = [
      [1970, 1, 1, 0, 0, 0],
      [1999, 12, 31, 23, 59, 59],
    ]
    for testCase in testCases
      time = Time.local(*testCase)
      assertEquals(PgTimestamp.new(*testCase).to_local_time, time)
    end
  end

  def test_to_utc_time
    testCases = [
      [1970, 1, 1, 0, 0, 0],
      [1999, 12, 31, 23, 59, 59],
    ]
    for testCase in testCases
      time = Time.utc(*testCase)
      assertEquals(PgTimestamp.new(*testCase).to_utc_time, time)
    end
  end

  def test_from_sql
    testCases = [
      [1900, 1, 1, 0, 0, 0],
      [1999, 12, 31, 23, 59, 59],
      [1999, 12, 31, 23, 59, 59, 98765],
    ]
    for testCase in testCases
      sql = "%04d-%02d-%02d %02d:%02d:%02d" % testCase[0..5]
      if testCase[6]
        sql += ".%6d" % testCase[6]
      end
      assertEquals(PgTimestamp.from_sql(sql), PgTimestamp.new(*testCase))
    end
  end

end

PgTimestampTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
