#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'

class NullConnectionTest < Test

  include SqlPostgres

  def testExec
    assertException(NoConnection) do
      NullConnection.new.exec("foo")
    end
  end

  def testClose
    assertException(NoConnection) do
      NullConnection.new.close
    end
  end

end

NullConnectionTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
