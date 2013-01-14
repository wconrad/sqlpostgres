require File.expand_path('../../lib/sqlpostgres', File.dirname(__FILE__))
require File.expand_path('test_database', File.dirname(__FILE__))

module TestSupport
  class PostgresTemplate

    def initialize(server_name, connection_args)
      @server_name = server_name
      @connection_args = connection_args
      @connection = template_connection
    end

    def create_database(db_name, database_encoding)
      return if db_exists?(db_name)
      puts "Creating database #{qualified_db_name(db_name)}"
      create_db(db_name, database_encoding)
    end

    def drop_database(db_name)
      return unless db_exists?(db_name)
      unless db_name =~ /^#{TestDatabase::NAME_PREFIX}/
        raise "Refusing to drop database #{qualified_db_name(db_name)}"
      end
      puts "Dropping database #{qualified_db_name(db_name)}"
      @connection.exec("drop database #{db_name}")
    end

    private

    def qualified_db_name(db_name)
      [@server_name, db_name].join('/')
    end

    def db_exists?(db_name)
      sql = SqlPostgres::Select.new(@connection)
      sql.select_literal(1)
      sql.from('pg_database')
      sql.where(['datname = %s', db_name])
      !sql.exec.empty?
    end

    def create_db(db_name, database_encoding)
      statement = [
        'create database', db_name,
        "with encoding '#{database_encoding}'",
        'template template0',
      ].join(' ')
      @connection.exec(statement)
    end

    def template_connection
      SqlPostgres::Connection.new(template_connection_args)
    end

    def template_connection_args
      @connection_args.merge(:db_name => 'template1')
    end

  end
end
