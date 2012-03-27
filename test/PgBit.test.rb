#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgBitTest < Test

  include SqlPostgres
  include RandomThings

  def test_ctor_defaults
    assertEquals(PgBit.new.bits, [])
  end

  def test_ctor_and_accessors
    bits = (0..4).collect do rand(2) end
    assertEquals(PgBit.new(bits).bits, bits)
    assertEquals(PgBit.new(bits.join.to_s).bits, bits)
  end

  def test_from_sql
    testCases = [
      ["", []],
      ["0", [0]],
      ["101", [1, 0, 1]],
    ]
    for testCase in testCases
      sql, bits = *testCase
      assertInfo("For sql #{sql.inspect}") do
        assertEquals(PgBit.from_sql(sql), PgBit.new(bits))
      end
    end
    assertException(ArgumentError, 'Invalid bit: "foo"') do
      PgBit.from_sql("foo")
    end
  end

  def test_equality
    fields = ["bits"]
    for field in fields
      assertInfo("For field #{field}") do
        bit1 = PgBit.new
        bit2 = PgBit.new
        assertEquals(bit1.eql?(bit2), true)
        assertEquals(bit1 == bit2, true)
        assertEquals(bit1 != bit2, false)
        args = fields.collect do |f|
          if f == field then 1 else 0 end
        end
        bit2 = PgBit.new(*args)
        assertEquals(bit1 == bit2, false)
        assertEquals(bit1 != bit2, true)
        assertEquals(bit1.eql?(Object.new), false)
        assertEquals(bit1 == Object.new, false)
      end
    end
  end

  def test_hash
    count = 0
    hashes = Hash.new(0)
    testHash = proc { |*args|
      assertEquals(PgBit.new(*args).hash, PgBit.new(*args).hash)
      hashes[PgBit.new(*args).hash] += 1
      count += 1
    }
    for i in (0...10)
      testHash.call(i)
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

  def test_to_s
    testCases = [
      [[], ""],
      [[1], "1"],
      [[1, 0, 1], "101"],
    ]
    for testCase in testCases
      bits, expected = *testCase
      bit = PgBit.new(bits)
      assertEquals(bit.to_s, expected)
      assertEquals(bit.to_sql, "bit '#{expected}'")
    end
  end

end

PgBitTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
