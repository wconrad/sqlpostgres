require File.join(File.dirname(__FILE__), "PgType")

module SqlPostgres

  # This class holds the value of a "point" column.

  class PgPolygon < PgType

    attr_reader :points

    class << self

      # Create a PgPolygon from a string in Postgres format

      def from_sql(s)
        if s =~ /^(\()\(.*\)(,\(.*\))?\)$/
          points = s.scan(/\([^(]*?\)/).collect do |t|
            PgPoint.from_sql(t)
          end
          PgPolygon.new(*points)
        else
          raise ArgumentError, "Invalid polygon: #{s.inspect}"
        end
      end

    end

    def initialize(*points)
      @points = points
    end

    def to_s
      "(#{points.join(", ")})"
    end

    protected

    def parts
      points
    end

    private

    def column_type
      'polygon'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
