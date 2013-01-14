require File.expand_path('PgType', File.dirname(__FILE__))

module SqlPostgres

  # This class holds the value of a "circle" column.

  class PgCircle < PgType

    # Return the center (PgPoint)

    attr_reader :center

    # Return the radius

    attr_reader :radius

    class << self

      # Create a PgCircle from a string in Postgres format

      def from_sql(s)
        if s =~ /^<(.*),(.*)>$/
          PgCircle.new(PgPoint.from_sql($1), $2.to_f)
        else
          raise ArgumentError, "Invalid circle: #{s.inspect}"
        end
      end

    end

    # Constructor

    def initialize(*args)
      case args.size
      when 0
        @center = PgPoint.new
        @radius = 0
      when 2
        @center = args[0]
        @radius = args[1]
      when 3
        @center = PgPoint.new(*args[0..1])
        @radius = args[2]
      else
        raise ArgumentError, "Incorrect number of arguments: #{args.size}"
      end
    end

    # Return a string representation (ie "<(1, 2), 3>").

    def to_s
      "<%s, %g>" % parts
    end

    protected

    def parts
      [center, radius]
    end

    private

    def column_type
      'circle'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
