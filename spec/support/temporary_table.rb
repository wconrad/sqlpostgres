require File.expand_path('../lib/temporary_table',
                         File.dirname(__FILE__))

RSpec.configure do |config|

  shared_context 'temporary table' do |args|

    def set_message_level(level)
      prior = connection.exec("show client_min_messages").first['client_min_messages']
      connection.exec("set client_min_messages = '#{level}'")
    ensure
      connection.exec("set client_min_messages = '#{prior}'")
    end

    around(:each) do |block|
      args = args.merge(:connection => connection)
      set_message_level('warning') do
        TestSupport::TemporaryTable.create(args, &block)
      end
    end

  end

end
