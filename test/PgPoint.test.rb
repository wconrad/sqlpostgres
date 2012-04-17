#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgPointTest < Test

  include SqlPostgres
  include RandomThings

  def test_ctor_defaults
    assertEquals(PgPoint.new, PgPoint.new(0, 0))
  end

  def test_ctor_and_accessors
    x = randomFloat
    y = randomFloat
    point = PgPoint.new(x, y)
    assertEquals(point.x, x)
    assertEquals(point.y, y)
  end

  def test_from_sql
    testCases = [
      ["(0,0)", [0, 0]],
      ["(1.2,-3)", [1.2, -3]],
      ["(1e+20,-1e+20)", [1e20, -1e20]],
    ]
    for testCase in testCases
      sql, args = *testCase
      assertInfo("For sql #{sql.inspect}") do
        assertEquals(PgPoint.from_sql(sql), PgPoint.new(*args))
      end
    end
    assertException(ArgumentError, 'Invalid point: "foo"') do
      PgPoint.from_sql("foo")
    end
  end

  def test_equality
    fields = ["x", "y"]
    for field in fields
      assertInfo("For field #{field}") do
        point1 = PgPoint.new
        point2 = PgPoint.new
        assertEquals(point1.eql?(point2), true)
        assertEquals(point1 == point2, true)
        assertEquals(point1 != point2, false)
        args = fields.collect do |f|
          if f == field then 1 else 0 end
        end
        point2 = PgPoint.new(*args)
        assertEquals(point1 == point2, false)
        assertEquals(point1 != point2, true)
        assertEquals(point1.eql?(Object.new), false)
        assertEquals(point1 == Object.new, false)
      end
    end
  end

  def test_hash
    count = 0
    hashes = Hash.new(0)
    testHash = proc { |*args|
      assertEquals(PgPoint.new(*args).hash, PgPoint.new(*args).hash)
      hashes[PgPoint.new(*args).hash] += 1
      count += 1
    }
    for i in (0...10)
      testHash.call(i, 0)
      testHash.call(0, i)
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

  def test_to_s
    testCases = [
      [[0, 0], "(0, 0)"],
      [[1.2, -2], "(1.2, -2)"],
      [[1e10, -1e10], "(1e+10, -1e+10)"],
    ]
    for testCase in testCases
      args, expected = *testCase
      assertEquals(PgPoint.new(*args).to_s, expected)
      assertEquals(PgPoint.new(*args).to_sql, "point '#{expected}'")
    end
  end

end

PgPointTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
