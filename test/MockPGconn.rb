class MockPGconn

  @@state = {}

  def MockPGconn.state
    @@state
  end

  def state
    @@state
  end

  def MockPGconn.connect(*args)
    @@state[:open] = true
    @@state[:openArgs] = args
    @@state[:connection] = MockPGconn.new
  end

  def set_client_encoding(encoding)
    @@state[:encoding] = encoding
  end
  
  def exec(statement)
    @@state[:statements] ||= []
    @@state[:statements] << statement
    result = (state[:results] || []).shift
    raise result if result.kind_of?(Exception)
    result
  end

  def close
    raise "Already closed" unless @@state[:open]
    @@state[:open] = false
    raise @@state[:close_exception] if @@state[:close_exception]
  end

end

module SqlPostgres

  class Connection

    def Connection.mockPgClass
      oldPgClass = @@pgClass
      begin
        MockPGconn.state.clear
        @@pgClass = MockPGconn
        yield
      ensure
        @@pgClass = oldPgClass
      end
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
