require File.expand_path('PgTwoPoints', File.dirname(__FILE__))

module SqlPostgres

  # This class holds the value of a "line segment" column.

  class PgLineSegment < PgTwoPoints

    class << self

      # Create a PgLineSegment from a string in Postgres format

      def from_sql(s)
        if s =~ /^\[(\(.*\)),(\(.*\))\]$/
          PgLineSegment.new(PgPoint.from_sql($1), PgPoint.from_sql($2))
        else
          raise ArgumentError, "Invalid lseg: #{s.inspect}"
        end
      end

    end

    private

    def column_type
      'lseg'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
