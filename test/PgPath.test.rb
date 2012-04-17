#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgPathTest < Test

  include SqlPostgres
  include RandomThings

  def test_ctor_defaults
    path = PgPath.new
    assertEquals(path.closed, true)
    assertEquals(path.points, [])
  end

  def test_ctor
    testCases = [
      [false, []],
      [true, []],
      [false, [PgPoint.new(1, 1)]],
      [false, [PgPoint.new(1, 1), PgPoint.new(2, 2)]],
    ]
    for testCase in testCases
      assertInfo("For test case #{testCase.inspect}") do
        closed, points = *testCase
        path = PgPath.new(closed, *points)
        assertEquals(path.points, points)
        assertEquals(path.closed, closed)
      end
    end
  end

  def test_from_sql
    testCases = [
      ["[(0,0)]", [false, PgPoint.new(0, 0)]],
      ["((1,2),(3,4))", [true, PgPoint.new(1, 2), PgPoint.new(3, 4)]],
    ]
    for sql, args in testCases
      assertInfo("For sql #{sql.inspect}") do
        assertEquals(PgPath.from_sql(sql), PgPath.new(*args))
      end
    end
    assertException(ArgumentError, 'Invalid path: "foo"') do
      PgPath.from_sql("foo")
    end
  end

  def test_to_s
    testCases = [
      [[false, PgPoint.new(1, 1)], "[(1, 1)]"],
      [[true, PgPoint.new(1, 1), PgPoint.new(2, 2)], "((1, 1), (2, 2))"],
    ]
    for args, expected in testCases
      assertInfo("For args #{args.inspect}") do
        assertEquals(PgPath.new(*args).to_s, expected)
        assertEquals(PgPath.new(*args).to_sql, "path '#{expected}'")
      end
    end
  end

  def test_equality
    path1 = PgPath.new(false)
    path2 = PgPath.new(false)
    assertEquals(path1.eql?(path2), true)
    assertEquals(path1 == path2, true)
    assertEquals(path1 != path2, false)
    for path2 in [PgPath.new(true), PgPath.new(false, PgPoint.new(1, 2))]
      assertEquals(path1 == path2, false)
      assertEquals(path1 != path2, true)
      assertEquals(path1.eql?(Object.new), false)
      assertEquals(path1 == Object.new, false)
    end
  end

  def test_hash
    count = 0
    hashes = Hash.new(0)
    testHash = proc { |*args|
      assertEquals(PgPath.new(*args).hash, PgPath.new(*args).hash)
      hashes[PgPath.new(*args).hash] += 1
      count += 1
    }
    for i in (1...10)
      testHash.call(false, PgPoint.new(0, 0), PgPoint.new(0, 0))
      testHash.call(true, PgPoint.new(0, 0), PgPoint.new(0, 0))
      testHash.call(false, PgPoint.new(i, 0), PgPoint.new(0, 0))
      testHash.call(false, PgPoint.new(0, i), PgPoint.new(0, 0))
      testHash.call(false, PgPoint.new(0, 0), PgPoint.new(i, 0))
      testHash.call(false, PgPoint.new(0, 0), PgPoint.new(0, i))
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

end

PgPathTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
