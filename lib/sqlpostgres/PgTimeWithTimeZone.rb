require File.expand_path('PgType', File.dirname(__FILE__))

module SqlPostgres

  # This class holds the value of a "time" column.

  class PgTimeWithTimeZone < PgType

    # Return the hour (0..23)

    attr_reader :hour

    # Return the minute (0..59)

    attr_reader :minute

    # Return the second (0..59)

    attr_reader :second

    # Return the hours of the time-zone offset.

    attr_reader :zone_hours

    # Return the minutes of the time-zone offset.

    attr_reader :zone_minutes

    class << self

      # Create a PgTimeWithTimeZone from a string in Postgres format
      # (ie "12:00:00+0800").

      def from_sql(s)
        if s =~ /^(\d+):(\d+):(\d+)((?:\+|-)\d+)(?::(\d+))?$/
          PgTimeWithTimeZone.new($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i)
        else
          raise ArgumentError, "Invalid time with time zone: #{s.inspect}"
        end
      end

    end

    # Constructor.
    #
    # [hour]
    #   0..23
    # [minute]
    #   0..59
    # [second}
    #   0..59
    # [zone_hours]
    #   The hours of the time-zone offset (-23..23)
    # [zone_minutes]
    #   The seconds of the time-zone offset (0..60)

    def initialize(hour = 0, minute = 0, second = 0, 
                   zone_hours = 0, zone_minutes = 0)
      @hour = hour
      @minute = minute
      @second = second
      @zone_hours = zone_hours
      @zone_minutes = zone_minutes
    end

    # Return a string representation (ie "12:00:00-07:00").

    def to_s
      "%02d:%02d:%02d%+03d:%02d" % parts
    end

    # Convert to sql format (ie "timestamp '2001-01-01 12:00:00'").

    def to_sql
      "time with time zone '#{to_s}'"
    end

    protected

    def parts
      [@hour, @minute, @second, @zone_hours, @zone_minutes]
    end

    private

    def column_type
      'time with time zone'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
