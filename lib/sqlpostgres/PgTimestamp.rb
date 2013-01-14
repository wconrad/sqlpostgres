require File.expand_path('PgType', File.dirname(__FILE__))

module SqlPostgres

  # This class holds the value of a "timestamp" column.

  class PgTimestamp < PgType

    attr_reader :year
    attr_reader :month
    attr_reader :day
    attr_reader :hour
    attr_reader :minute
    attr_reader :second
    attr_reader :microseconds

    class << self

      # Convert from Postgres (ie '2001-01-01 12:00:01') to a PgTimestamp

      def from_sql(s)
        PgTimestamp.new(*s.gsub(/\D/, ' ').split.collect do |q| q.to_i end)
      end

    end

    # Constructor taking all the pieces.

    def initialize(year = 0, month = 0, day = 0, 
                   hour = 0, minute = 0, second = 0,
                   microseconds = 0)
      @year = year
      @month = month
      @day = day
      @hour = hour
      @minute = minute
      @second = second
      @microseconds = microseconds
    end

    # Convert to a string (ie '2001-01-01 12:00:00').

    def to_s
      "%04d-%02d-%02d %02d:%02d:%02d.%05d" % parts
    end

    # Convert to sql format (ie "timestamp '2001-01-01 12:00:00'").

    def to_sql
      "timestamp '#{to_s}'"
    end

    # Convert to an instance of Time in the local time zone.
    #
    # Note: Time can't take all the values that PgTimestamp can, so
    # this method can easily raise an exception.  Only use it if
    # you're sure that the PgTimestamp will fit in a Time.

    def to_local_time
      Time.local(@year, @month, @day, @hour, @minute, @second)
    end

    # Convert to an instance of Time in the utc time zone.  
    #
    # Note: Time can't take all the values that PgTimestamp can, so
    # this method can easily raise an exception.  Only use it if
    # you're sure that the PgTimestamp will fit in a Time.

    def to_utc_time
      Time.utc(@year, @month, @day, @hour, @minute, @second)
    end

    protected

    def parts
      [@year, @month, @day, @hour, @minute, @second, @microseconds]
    end

    private

    def column_type
      'timestamp'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
