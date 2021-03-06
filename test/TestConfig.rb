module TestConfig

  # The path to the library

  LIB_PATH = "../lib/sqlpostgres"

  # The name of the database to use for testing.

  TEST_DB_NAME = "sqlpostgres_test"

  # The database port to use for testing.

  TEST_DB_PORT = ENV['PGPORT'] || 5432

  # The prefix for temporary database objects.

  TEST_DB_PREFIX = "SQLPOSTGRES_TEST_"

  # Encodings

  TEST_CLIENT_ENCODING = 'SQL_ASCII'
  TEST_DB_ENCODING = 'SQL_ASCII'

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
