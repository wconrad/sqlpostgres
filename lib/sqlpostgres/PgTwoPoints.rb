require File.expand_path('PgType', File.dirname(__FILE__))

module SqlPostgres

  # This is the base class for data types which have two points

  class PgTwoPoints < PgType

    # Return the first endpoint

    attr_reader :p1

    # Return the second endpoint

    attr_reader :p2

    # Constructor.  Takes either 0 arguments, which sets both endpoints
    # to (0, 0), or 2 PgPoint arguments, or 4 float arguments.

    def initialize(*args)
      case args.size
      when 0
        @p1 = PgPoint.new
        @p2 = PgPoint.new
      when 2
        @p1 = args[0]
        @p2 = args[1]
      when 4
        @p1 = PgPoint.new(*args[0..1])
        @p2 = PgPoint.new(*args[2..3])
      end
    end

    # Return a string representation (ie "((1, 2), (3, 4))").

    def to_s
      "(%s, %s)" % [p1, p2]
    end

    protected

    def parts
      [p1, p2]
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
