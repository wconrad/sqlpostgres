module SqlPostgres

  # This is the base class for the classes that represent column types.

  class PgType

    # Return true if +other+ is is equal to this object.

    def eql?(other)
      other.is_a?(self.class) && parts == other.parts
    end
    alias_method :==, :eql?

    # Return the hash code.

    def hash
      parts.to_s.hash
    end

    # Return the SQL representation.

    def to_sql
      "#{column_type} '#{to_s}'"
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
