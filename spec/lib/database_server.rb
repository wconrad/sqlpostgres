require File.expand_path('postgres_template', File.dirname(__FILE__))
require File.expand_path('test_database', File.dirname(__FILE__))

module TestSupport
  class DatabaseServer

    attr_reader :test_databases

    def initialize(name, connection_args, encodings)
      @server_name = name
      @encodings = encodings
      @connection_args = connection_args
      @template = PostgresTemplate.new(@server_name, connection_args)
      @test_databases = test_databases
    end

    def test_connections
      @test_databases.map(&:test_connections).flatten
    end

    def drop_databases
      test_databases.each do |test_database|
        test_database.drop(@template)
      end
    end

    def create_databases
      test_databases.each do |test_database|
        test_database.create(@template)
      end
    end

    private

    def test_databases
      @encodings.map do |encoding|
        TestDatabase.new(@server_name, @connection_args, encoding)
      end
    end

  end
end
