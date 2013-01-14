module TestSupport

  class TemporaryTable

    def self.create(*args)
      table = new(*args)
      table.drop if table.exists?
      table.create
      begin
        yield
      ensure
        table.drop
      end
    end

    def initialize(args)
      @connection = args[:connection]
      @table_name = args[:table_name]
      @columns = args[:columns]
    end

    def exists?
      sql = SqlPostgres::Select.new(@connection)
      sql.select_literal(1)
      sql.from('pg_class')
      sql.where(['relname = %s', @table_name])
      !sql.exec.empty?
    end

    def create
      statement = [
        'create temporary table', @table_name,
        "(#{@columns.join(', ')})",
      ].join(' ')
      @connection.exec statement
    end

    def drop
      statement = "drop table #{@table_name}"
      @connection.exec statement
    end

  end

end
