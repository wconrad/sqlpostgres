#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'RandomThings'

class PgIntervalTest < Test

  include SqlPostgres
  include RandomThings

  FIELDS = [
    "millennia", "centuries", "decades",
    "years", "months", "days", "weeks",
    "hours", "minutes", "seconds",
    "ago"
  ]

  def test_ctor_and_accessors
    for ago in [false, true]
      args = Hash[*FIELDS.collect do |field| 
          [field, randomInteger] 
        end.flatten]
      args['ago'] = ago
      interval = PgInterval.new(args)
      assertInfo("For ago=#{ago}") do
        for field, value in args
          assertInfo("For field=#{field}") do
            assertEquals(interval.send(field), value)
          end
          assertEquals(interval.ago, ago)
        end
      end
    end
  end

  def test_ctor_invlaid_args
    assertException(ArgumentError, '{"foo"=>1}') do
      PgInterval.new('foo'=>1)
    end
  end

  def test_ctor_defaults
    args = Hash[*FIELDS.collect do |field| 
        [field, field == 'ago' ? false : 0] 
      end.flatten]
    assertEquals(PgInterval.new, PgInterval.new(args))
  end

  def test_equality
    for field in FIELDS
      assertInfo("For field #{field}") do
        time1 = PgInterval.new
        time2 = PgInterval.new
        assertEquals(time1.eql?(time2), true)
        assertEquals(time1 == time2, true)
        assertEquals(time1 != time2, false)
        time2 = PgInterval.new(field=>1)
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
    for i in (0...9)
      for field in FIELDS
        args = {field=>i}
        assertEquals(PgInterval.new(args).hash, PgInterval.new(args).hash)
        hashes[PgInterval.new(args).hash] += 1
        count += 1
      end
    end
    assertGreaterOrEqual(hashes.size.to_f / count, 0.5)
  end

  def test_to_s
    testCases = [
      [{}, "0 days"],
      [{"seconds"=>2}, "00:00:02"],
      [{"minutes"=>2}, "00:02"],
      [{"hours"=>2}, "02:00"],
      [{"hours"=>1, "minutes"=>2, "seconds"=>3}, "01:02:03"],
      [{"days"=>2}, "2 days"],
      [{"weeks"=>2}, "2 weeks"],
      [{"months"=>2}, "2 months"],
      [{"years"=>2}, "2 years"],
      [{"decades"=>2}, "2 decades"],
      [{"centuries"=>2}, "2 centuries"],
      [{"millennia"=>2}, "2 millennia"],
      [{"seconds"=>1}, "00:00:01"],
      [{"minutes"=>1}, "00:01"],
      [{"hours"=>1}, "01:00"],
      [{"days"=>1}, "1 day"],
      [{"weeks"=>1}, "1 week"],
      [{"months"=>1}, "1 month"],
      [{"years"=>1}, "1 year"],
      [{"decades"=>1}, "1 decade"],
      [{"centuries"=>1}, "1 century"],
      [{"millennia"=>1}, "1 millennium"],
      [{"years"=>1, "days"=>2}, "1 year 2 days"],
      [ {
          'centuries'=>2, 'decades'=>3, 'years'=>4, 'months'=>5,
          'weeks'=>6, 'days'=>7, 'hours'=>8, 'minutes'=>9, 'seconds'=>10
        },
        "2 centuries 3 decades 4 years 5 months 6 weeks 7 days 08:09:10"
      ],
      [{"days"=>1, "ago"=>false}, "1 day"],
      [{"days"=>1, "ago"=>true}, "1 day ago"],
      [{"days"=>-1}, "-1 days"],
      [{"days"=>-1, "ago"=>true}, "-1 days ago"],
      [{"ago"=>true}, "0 days ago"],
      [{"seconds"=>1.123456}, "00:00:01.123456"],
      [{"seconds"=>59.999999}, "00:00:59.999999"],
      [{"hours"=>1, "minutes"=>1, "seconds"=>1}, "01:01:01"],
      [{"hours"=>-1, "minutes"=>-1, "seconds"=>-1}, "-01:01:01"],
      [
        {"hours"=>1, "minutes"=>-1, "seconds"=>1}, 
        "1 hour -1 minutes 1 second"
      ],
    ]
    for args, expected in testCases
      assertInfo("For args=#{args.inspect}") do
        assertEquals(PgInterval.new(args).to_s, expected)
        assertEquals(PgInterval.new(args).to_sql, "interval '#{expected}'")
      end
    end
  end

  def test_from_sql
    testCases = [
      ["00:00", PgInterval.new],
      ["01:02", PgInterval.new('hours'=>1, 'minutes'=>2)],
      ["01:02:03", PgInterval.new('hours'=>1, 'minutes'=>2, 'seconds'=>3)],
      ["-01:02:03", PgInterval.new('hours'=>-1, 'minutes'=>-2, 'seconds'=>-3)],
      ["1 day", PgInterval.new('days'=>1)],
      ["2 days", PgInterval.new('days'=>2)],
      ["2 days 03:00", PgInterval.new('days'=>2, 'hours'=>3)],
      ["1 mon", PgInterval.new('months'=>1)],
      ["2 mons", PgInterval.new('months'=>2)],
      ["00:00:01.100000", PgInterval.new('seconds'=>1.1)],
    ]
    for sql, interval in testCases
      assertInfo("For sql=#{sql.inspect}") do
        assertEquals(PgInterval.from_sql(sql), interval)
      end
    end
  end

  def test_from_sql_exceptions
    testCases = [
      "",
      "1 foo",
      "foo",
    ]
    for sql in testCases
      assertInfo("For sql=#{sql.inspect}") do
        message = "Syntax error in interval: #{sql.inspect}"
        assertException(ArgumentError, message) do
          PgInterval.from_sql(sql)
        end
      end
    end
  end

end

PgIntervalTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
