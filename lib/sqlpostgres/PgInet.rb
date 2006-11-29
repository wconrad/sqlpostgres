require 'sqlpostgres/PgWrapper'

module SqlPostgres

  # This class holds the value of an "inet" column.

  class PgInet < PgWrapper

    def column_type
      'inet'
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
