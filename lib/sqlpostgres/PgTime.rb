require File.expand_path('PgType', File.dirname(__FILE__))

module SqlPostgres

  # This class holds the value of a "time" column.

  class PgTime < PgType

    # Return the hour (0..23)

    attr_reader :hour

    # Return the minute (0..59)

    attr_reader :minute

    # Return the second (0..59)

    attr_reader :second

    class << self

      # Create a PgTime from a string in Postgres format (ie "12:00:00").

      def from_sql(s)
        PgTime.new(*s.split(":").collect do |p| p.to_i end)
      end

    end

    # Constructor taking hour (0..23), minute (0..59), and second (0..59)

    def initialize(hour = 0, minute = 0, second = 0)
      @hour = hour
      @minute = minute
      @second = second
    end

    # Return a string representation (ie "12:00:00").

    def to_s
      "%02d:%02d:%02d" % [@hour, @minute, @second]
    end

    # Convert to an instance of Time on date 1970/01/01, local time zone.

    def to_local_time
      Time.local(1970, 1, 1, @hour, @minute, @second)
    end

    # Convert to an instance of Time on date 1970/01/01, utc time zone.

    def to_utc_time
      Time.utc(1970, 1, 1, @hour, @minute, @second)
    end

    protected

    def parts
      [hour, minute, second]
    end

    private

    def column_type
      'time'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
