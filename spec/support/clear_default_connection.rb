RSpec.configure do |config|
  config.after(:each) do
    SqlPostgres::Connection.default = nil
  end
end
