module SqlPostgres

  # A function requiring a database connection was called, but the object
  # didn't have a database connection.

  class NoConnection < Exception
  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
