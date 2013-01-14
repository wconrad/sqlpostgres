require File.expand_path('PgWrapper', File.dirname(__FILE__))

module SqlPostgres

  # This class holds the value of an "macaddr" column.

  class PgMacAddr < PgWrapper

    def column_type
      'macaddr'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
