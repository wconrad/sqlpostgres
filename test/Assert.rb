module Assert

  class BlownAssert < Exception

    attr_accessor :message

    def initialize(message = "")
      @message = message
    end

    def to_s
      @message
    end
  end

  def assert(condition)
    fail("Assert failed") unless condition
  end

  def assertEquals(actual, expected)
    return if expected === actual
    fail("Expected:\n#{expected.inspect}\nbut got\n#{actual.inspect}")
  end
  module_function :assertEquals

  def assertGreater(actual, expected)
    return if actual > expected
    fail("Expected > #{expected.inspect} but got #{actual.inspect}")
  end

  def assertGreaterOrEqual(actual, expected)
    return if actual >= expected
    fail("Expected >= #{expected.inspect} but got #{actual.inspect}")
  end

  def assertException(exceptionClass, exceptionString = nil)
    begin
      yield
    rescue exceptionClass => e
      assertEquals(e.to_s, exceptionString) unless exceptionString.nil?
    else
      fail("Exception #{exceptionClass} not thrown")
    end
  end

  def assertInfo(info)
    begin
      yield
    rescue Exception => e
      newMessage = "#{info}: #{e}"
      if e.is_a? BlownAssert
        e.message = newMessage
        raise
      else
        newMessage << "\nOriginal backtrace:\n#{e.backtrace.join("\n")}"
        raise e.exception(newMessage)
      end
    end
  end

  def fail(why)
    raise BlownAssert, why
  end
  module_function :fail

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
