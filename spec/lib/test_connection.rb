require 'memoizer'

module TestSupport
  class TestConnection

    include Memoizer

    def initialize(test_database, client_encoding)
      @test_database = test_database
      @client_encoding = client_encoding
    end

    def context
      "(#{@test_database.context} client-encoding=#{@client_encoding})"
    end

    def connection
      SqlPostgres::Connection.new(connection_args)
    end
    memoize :connection

    private

    def connection_args
      @test_database.connection_args.merge('encoding' => @client_encoding)
    end

  end
end
