require 'sqlpostgres/PgType'

module SqlPostgres

  # This PgType is the base class of wrapper types that are merely
  # wrappers around String.  Its purpose is to identify the type of
  # String (is it a mac address?  An inet address? etc).

  class PgWrapper < PgType

    class << self

      def from_sql(sql)
        self.new(sql)
      end

    end

    def initialize(value)
      @value = value
    end

    def to_s
      @value
    end

    protected

    def parts
      [@value]
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
