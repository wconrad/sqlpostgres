require File.expand_path('PgType', File.dirname(__FILE__))

module SqlPostgres

  # This class holds the value of a "path" column.

  class PgPath < PgType

    attr_reader :points
    attr_reader :closed

    class << self

      # Create a PgPath from a string in Postgres format

      def from_sql(s)
        if s =~ /^(\[)\(.*\)(,\(.*\))?\]$/ || s =~ /^(\()\(.*\)(,\(.*\))?\)$/
          closed = $1 == "("
          points = s.scan(/\([^(]*?\)/).collect do |t|
            PgPoint.from_sql(t)
          end
          PgPath.new(closed, *points)
        else
          raise ArgumentError, "Invalid path: #{s.inspect}"
        end
      end

    end

    def initialize(closed = true, *points)
      @points = points
      @closed = closed
    end

    def to_s
      s = points.join(", ")
      if closed
        "(#{s})"
      else
        "[#{s}]"
      end
    end

    protected

    def parts
      [closed, points]
    end

    private

    def column_type
      'path'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
