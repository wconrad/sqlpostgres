require File.expand_path('../lib/target_database_servers',
                         File.dirname(__FILE__))

def test_connections
  TestSupport::TargetDatabaseServers.instance.test_connections
end

def test_connection
  TestSupport::TargetDatabaseServers.instance.test_connection
end
