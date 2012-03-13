require 'Assert'
require 'TestUtil'

class Test
  
  include Assert
  include TestUtil

  private
  
  def allInstanceMethods
    self.class.public_instance_methods(false) + 
      self.class.private_instance_methods(false)
  end
  
  public
  
  def doRun
    testForTestDb
    allInstanceMethods.each { |methodName|
      case methodName
      when /^skip_test/
        $stderr.puts "Warning: Commented out test #{methodName}"
      when /^test/
        aMethod = method(methodName)
        if aMethod.arity == 0
          #$stderr.puts methodName
          setup
          begin
            aMethod.call
          ensure
            tearDown
          end
        end
      end
    }
  end
  
  def run
    begin
      doRun
    rescue Exception => e
      $stderr.puts "#{e.class}: #{e}", e.backtrace
      exit 1
    end
  end
  
  private

  def setup
  end
  
  def tearDown
  end
  
end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
