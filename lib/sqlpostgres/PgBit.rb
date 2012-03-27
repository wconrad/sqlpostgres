require 'sqlpostgres/PgType'

module SqlPostgres

  # This class holds the value of a "bit" column.

  class PgBit < PgType

    # Return an array of 0's and 1's with the bits.

    attr_reader :bits

    class << self

      # Create a PgBit from a string in Postgres format (ie
      # "(1,2)").

      def from_sql(s)
        if s =~ /^[01]*$/
          PgBit.new(s)
        else
          raise ArgumentError, "Invalid bit: #{s.inspect}"
        end
      end

    end

    # Constructor.  Takes either an array of bits, a bunch of bits, or
    # a string.  These are all equivalent:
    #   PgBit.new([0, 1, 0, 1])
    #   PgBit.new(0, 1, 0, 1)
    #   PgBit.new("0101")

    def initialize(*args)
      args = args.flatten
      if args.size == 1 && args[0].is_a?(String)
        @bits = bits_from_sql(args[0])
      else
        @bits = args
      end
    end

    # Return a string representation (ie "01011").

    def to_s
      bits.join
    end

    protected

    def parts
      [bits]
    end

    private

    def column_type
      'bit'
    end

    def bits_from_sql(s)
      s.scan(/./).collect do |d| d.to_i end
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
