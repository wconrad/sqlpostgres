#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgPolygonTest < Test

  include SqlPostgres
  include RandomThings

  def test_ctor_defaults
    assertEquals(PgPolygon.new.points, [])
  end

  def test_ctor
    testCases = [
      [],
      [PgPoint.new(1, 1)],
      [PgPoint.new(1, 1), PgPoint.new(2, 2)],
    ]
    for points in testCases
      assertEquals(PgPolygon.new(*points).points, points)
    end
  end

  def test_from_sql
    testCases = [
      ["((0,0))", [PgPoint.new(0, 0)]],
      ["((1,2),(3,4))", [PgPoint.new(1, 2), PgPoint.new(3, 4)]],
    ]
    for sql, args in testCases
      assertInfo("For sql #{sql.inspect}") do
        assertEquals(PgPolygon.from_sql(sql), PgPolygon.new(*args))
      end
    end
    assertException(ArgumentError, 'Invalid polygon: "foo"') do
      PgPolygon.from_sql("foo")
    end
  end

  def test_to_s
    testCases = [
      [[PgPoint.new(1, 1)], "((1, 1))"],
      [[PgPoint.new(1, 1), PgPoint.new(2, 2)], "((1, 1), (2, 2))"],
    ]
    for args, expected in testCases
      assertInfo("For args #{args.inspect}") do
        assertEquals(PgPolygon.new(*args).to_s, expected)
        assertEquals(PgPolygon.new(*args).to_sql, "polygon '#{expected}'")
      end
    end
  end

  def test_equality
    polygon1 = PgPolygon.new(false)
    polygon2 = PgPolygon.new(false)
    assertEquals(polygon1.eql?(polygon2), true)
    assertEquals(polygon1 == polygon2, true)
    assertEquals(polygon1 != polygon2, false)
    polygon2 = PgPolygon.new(PgPoint.new(1, 2))
    assertEquals(polygon1 == polygon2, false)
    assertEquals(polygon1 != polygon2, true)
    assertEquals(polygon1.eql?(Object.new), false)
    assertEquals(polygon1 == Object.new, false)
  end

  def test_hash
    count = 0
    hashes = Hash.new(0)
    testHash = proc { |*args|
      assertEquals(PgPolygon.new(*args).hash, PgPolygon.new(*args).hash)
      hashes[PgPolygon.new(*args).hash] += 1
      count += 1
    }
    for i in (0...10)
      testHash.call(PgPoint.new(i, 0), PgPoint.new(0, 0))
      testHash.call(PgPoint.new(0, i), PgPoint.new(0, 0))
      testHash.call(PgPoint.new(0, 0), PgPoint.new(i, 0))
      testHash.call(PgPoint.new(0, 0), PgPoint.new(0, i))
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

end

PgPolygonTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
