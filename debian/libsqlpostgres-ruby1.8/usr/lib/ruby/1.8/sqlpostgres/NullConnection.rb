module SqlPostgres

  # This is a special connection that is used when there isn't a real
  # one.  Any attempt to use it causes a NoConnection exception.

  class NullConnection

    # Raises NoConnection

    def method_missing(method, *args)
      raise NoConnection
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
