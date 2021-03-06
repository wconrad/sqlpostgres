#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgBoxTest < Test

  include SqlPostgres
  include RandomThings

   def test_ctor_defaults
     assertEquals(PgBox.new, PgBox.new(PgPoint.new, PgPoint.new))
   end

  def test_ctor_and_accessors
    p1 = randomWhatever
    p2 = randomWhatever
    line = PgBox.new(p1, p2)
    assertEquals(line.p1, p1)
    assertEquals(line.p2, p2)

    x1 = randomFloat
    x2 = randomFloat
    y1 = randomFloat
    y2 = randomFloat
    line = PgBox.new(x1, y1, x2, y2)
    assertEquals(line.p1, PgPoint.new(x1, y1))
    assertEquals(line.p2, PgPoint.new(x2, y2))
  end

  def test_from_sql
    testCases = [
      ["(0,0),(0,0)", [0, 0, 0, 0]],
      ["(1.2,-3),(1e+20,-1e20)", [1.2, -3, 1e+20, -1e20]],
    ]
    for testCase in testCases
      sql, args = *testCase
      assertInfo("For sql #{sql.inspect}") do
        assertEquals(PgBox.from_sql(sql), PgBox.new(*args))
      end
    end
    assertException(ArgumentError, 'Invalid box: "foo"') do
      PgBox.from_sql("foo")
    end
  end

  def test_equality
    fields = ["p1", "p2"]
    for field in fields
      assertInfo("For field #{field}") do
        line1 = PgBox.new
        line2 = PgBox.new
        assertEquals(line1.eql?(line2), true)
        assertEquals(line1 == line2, true)
        assertEquals(line1 != line2, false)
        args = fields.collect do |f|
          if f == field then 1 else 0 end
        end
        line2 = PgBox.new(*args)
        assertEquals(line1 == line2, false)
        assertEquals(line1 != line2, true)
        assertEquals(line1.eql?(Object.new), false)
        assertEquals(line1 == Object.new, false)
      end
    end
  end

  def test_hash
    count = 0
    hashes = Hash.new(0)
    testHash = proc { |*args|
      assertEquals(PgBox.new(*args).hash, PgBox.new(*args).hash)
      hashes[PgBox.new(*args).hash] += 1
      count += 1
    }
    for i in (0...10)
      testHash.call(i, 0, 0, 0)
      testHash.call(0, i, 0, 0)
      testHash.call(0, 0, i, 0)
      testHash.call(0, 0, 0, i)
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

  def test_to_s
    testCases = [
      [[0, 0, 0, 0], "((0, 0), (0, 0))"],
      [[1.2, -2, 1e10, -1e10], "((1.2, -2), (1e+10, -1e+10))"],
    ]
    for testCase in testCases
      args, expected = *testCase
      assertEquals(PgBox.new(*args).to_s, expected)
      assertEquals(PgBox.new(*args).to_sql, "box '#{expected}'")
    end
  end

end

PgBoxTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
