require File.expand_path('PgType', File.dirname(__FILE__))

module SqlPostgres

  # This class holds the value of a "point" column.

  class PgPoint < PgType

    # Return the x coordinate

    attr_reader :x

    # Return the y coordinate

    attr_reader :y

    class << self

      # Create a PgPoint from a string in Postgres format (ie
      # "(1,2)").

      def from_sql(s)
        if s =~ /^\((.*?),(.*\))$/
          PgPoint.new($1.to_f, $2.to_f)
        else
          raise ArgumentError, "Invalid point: #{s.inspect}"
        end
      end

    end

    # Constructor taking the x and y coordinate

    def initialize(x = 0, y = 0)
      @x = x
      @y = y
    end

    # Return a string representation (ie "(1, 2)").

    def to_s
      "(%g, %g)" % parts
    end

    protected

    def parts
      [x, y]
    end

    private

    def column_type
      'point'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
