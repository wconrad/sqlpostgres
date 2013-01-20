require 'memoizer'
require 'singleton'
require File.expand_path('database_config', File.dirname(__FILE__))
require File.expand_path('database_server', File.dirname(__FILE__))
require File.expand_path('test_config', File.dirname(__FILE__))

module TestSupport
  class TargetDatabaseServers

    include Memoizer
    include Singleton

    def test_connections
      database_servers.map(&:test_connections).flatten.map do |test_connection|
        [test_connection.context, test_connection.connection]
      end
    end
    memoize :test_connections

    def test_connection
      test_connections.last
    end

    def create_databases
      database_servers.each(&:create_databases)
    end

    def drop_databases
      database_servers.each(&:drop_databases)
    end

    private

    def database_servers
      database_config.map do |config_name, config|
        DatabaseServer.new(config_name, config, encodings)
      end
    end

    def encodings
      test_config['encodings']
    end

    def test_config
      TestConfig.new
    end
    memoize :test_config

    def database_config
      DatabaseConfig.new
    end
    memoize :database_config

  end
end
