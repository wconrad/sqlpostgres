#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgInetTest < Test

  include SqlPostgres
  include RandomThings

  def test
    ipAndMask = randomString
    assertEquals(PgInet.new(ipAndMask), PgInet.from_sql(ipAndMask))
    assertEquals(PgInet.new(ipAndMask).to_s, ipAndMask)
    assertEquals(PgInet.new(ipAndMask).to_sql, "inet '#{ipAndMask}'")
  end

  def test_equality
    testCases = [
      ["a", "a", true],
      ["a", "b", false],
      ["b", "a", false],
    ]
    for testCase in testCases
      assertInfo("For test case #{testCase.inspect}") do
        argA, argB, equal = *testCase
        a = PgInet.new(argA)
        b = PgInet.new(argB)
        assertEquals(a == b, equal)
        assertEquals(a.eql?(b), equal)
        assertEquals(a != b, !equal)
      end
    end
  end

  def test_hash
    count = 0
    hashes = Hash.new(0)
    testHash = proc { |*args|
      assertEquals(PgInet.new(*args).hash, PgInet.new(*args).hash)
      hashes[PgInet.new(*args).hash] += 1
      count += 1
    }
    for i in (0...10)
      testHash.call(i.to_s)
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

end

PgInetTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
