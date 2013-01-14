require File.expand_path('../lib/temporary_table',
                         File.dirname(__FILE__))

RSpec.configure do |config|

  shared_context 'temporary table' do |args|

    around(:each) do |block|
      TestSupport::TemporaryTable.create(args, &block)
    end

  end

end
