require File.expand_path('PgWrapper', File.dirname(__FILE__))

module SqlPostgres

  # This class holds the value of an "cidr" column.

  class PgCidr < PgWrapper

    def column_type
      'cidr'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
