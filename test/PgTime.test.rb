#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgTimeTest < Test

  include SqlPostgres
  include RandomThings

  def test_ctor_defaults
    assertEquals(PgTime.new, PgTime.new(0, 0, 0))
  end

  def test_ctor_and_accessors
    hour = randomInteger
    minute = randomInteger
    second = randomInteger
    time = PgTime.new(hour, minute, second)
    assertEquals(time.hour, hour)
    assertEquals(time.minute, minute)
    assertEquals(time.second, second)
  end

  def test_from_sql
    testCases = [
      [0, 0, 0],
      [23, 59, 59],
    ]
    for testCase in testCases
      sql = "%02d:%02d:%02d" % testCase
    assertEquals(PgTime.from_sql(sql), PgTime.new(*testCase))
    end
  end

  def test_equality
    fields = ["hour", "minute", "second"]
    for field in fields
      assertInfo("For field #{field}") do
        time1 = PgTime.new
        time2 = PgTime.new
        assertEquals(time1.eql?(time2), true)
        assertEquals(time1 == time2, true)
        assertEquals(time1 != time2, false)
        args = fields.collect do |f|
          if f == field then 1 else 0 end
        end
        time2 = PgTime.new(*args)
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
      assertEquals(PgTime.new(*args).hash, PgTime.new(*args).hash)
      hashes[PgTime.new(*args).hash] += 1
      count += 1
    }
    for i in (0...10)
      testHash.call(i, 0, 0)
      testHash.call(0, i, 0)
      testHash.call(0, 0, i)
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

  def test_to_s
    testCases = [
      [[0, 0, 0], "00:00:00"],
      [[23, 59, 59], "23:59:59"],
    ]
    for testCase in testCases
      args, expected = *testCase
      assertEquals(PgTime.new(*args).to_s, expected)
      assertEquals(PgTime.new(*args).to_sql, "time '#{expected}'")
    end
  end

  def test_to_local_time
    testCases = [
      [0, 0, 0],
      [12, 13, 14],
      [23, 59, 59],
    ]
    for testCase in testCases
      time = Time.local(1970, 1, 1, *testCase)
      assertEquals(PgTime.new(*testCase).to_local_time, time)
    end
  end

  def test_to_utc_time
    testCases = [
      [0, 0, 0],
      [12, 13, 14],
      [23, 59, 59],
    ]
    for testCase in testCases
      time = Time.utc(1970, 1, 1, *testCase)
      assertEquals(PgTime.new(*testCase).to_utc_time, time)
    end
  end

end

PgTimeTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
