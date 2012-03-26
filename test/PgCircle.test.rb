#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgCircleTest < Test

  include SqlPostgres
  include RandomThings

  def test_ctor_defaults
    assertEquals(PgCircle.new, PgCircle.new(0, 0, 0))
  end

  def test_ctor_and_accessors
    x = randomFloat
    y = randomFloat
    radius = randomFloat
    circle = PgCircle.new(x, y, radius)
    assertEquals(circle.center, PgPoint.new(x, y))
    assertEquals(circle.radius, radius)
    circle = PgCircle.new(PgPoint.new(x, y), radius)
    assertEquals(circle.center, PgPoint.new(x, y))
    assertEquals(circle.radius, radius)
    assertException(ArgumentError, "Incorrect number of arguments: 1") do
      PgCircle.new(1)
    end
  end

  def test_from_sql
    testCases = [
      ["<(1,2),3>", [1, 2, 3]],
      ["<(1,2.3),1e+30>", [1, 2.3, 1e30]],
    ]
    for testCase in testCases
      sql, args = *testCase
      assertInfo("For sql #{sql.inspect}") do
        assertEquals(PgCircle.from_sql(sql), PgCircle.new(*args))
      end
    end
    assertException(ArgumentError, 'Invalid circle: "foo"') do
      PgCircle.from_sql("foo")
    end
  end

  def test_equality
    fields = ["center", "radius"]
    for field in fields
      assertInfo("For field #{field}") do
        circle1 = PgCircle.new
        circle2 = PgCircle.new
        assertEquals(circle1.eql?(circle2), true)
        assertEquals(circle1 == circle2, true)
        assertEquals(circle1 != circle2, false)
        args = fields.collect do |f|
          if f == field then 1 else 0 end
        end
        circle2 = PgCircle.new(*args)
        assertEquals(circle1 == circle2, false)
        assertEquals(circle1 != circle2, true)
        assertEquals(circle1.eql?(Object.new), false)
        assertEquals(circle1 == Object.new, false)
      end
    end
  end

  def test_hash
    count = 0
    hashes = Hash.new(0)
    testHash = proc { |*args|
      assertEquals(PgCircle.new(*args).hash, PgCircle.new(*args).hash)
      hashes[PgCircle.new(*args).hash] += 1
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
      [[0, 0, 0], "<(0, 0), 0>"],
      [[1.2, -2, 1e10], "<(1.2, -2), 1e+10>"],
    ]
    for testCase in testCases
      args, expected = *testCase
      circle = PgCircle.new(*args)
      assertEquals(circle.to_s, expected)
      assertEquals(circle.to_sql, "circle '#{expected}'")
    end
  end

end

PgCircleTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
