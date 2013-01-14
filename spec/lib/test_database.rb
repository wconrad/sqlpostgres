require 'memoizer'
require File.expand_path('test_connection', File.dirname(__FILE__))

module TestSupport
  class TestDatabase

    include Memoizer

    attr_reader :connection_args

    NAME_PREFIX = 'sqlpostgres_test_'

    def initialize(name, connection_args, encoding)
      @name = name
      @connection_args = connection_args
      @encoding = encoding
    end

    def create(template)
      template.create_database(db_name, database_encoding)
    end

    def drop(template)
      template.drop_database(db_name)
    end

    def context
      "db=#{@name} db-encoding=#{database_encoding}"
    end

    def test_connections
      client_encodings.map do |client_encoding|
        TestConnection.new(self, client_encoding)
      end
    end

    def connection_args
      @connection_args.merge('db_name' => db_name)
    end

    def db_name
      "#{NAME_PREFIX}#{database_encoding}"
    end

    private

    def database_encoding
      @encoding['database_encoding']
    end

    def client_encodings
      @encoding['client_encodings']
    end

  end
end
