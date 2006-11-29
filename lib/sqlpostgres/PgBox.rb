require 'sqlpostgres/PgTwoPoints'

module SqlPostgres

  # This class holds the value of a "point" column.

  class PgBox < PgTwoPoints

    class << self

      # Create a PgBox from a string in Postgres format

      def from_sql(s)
        if s =~ /^(\(.*\)),(\(.*\))$/
          PgBox.new(PgPoint.from_sql($1), PgPoint.from_sql($2))
        else
          raise ArgumentError, "Invalid box: #{s.inspect}"
        end
      end

    end

    private

    def column_type
      'box'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
