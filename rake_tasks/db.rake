namespace 'test:db' do

  def target_database_servers
    TestSupport::TargetDatabaseServers.instance
  end

  desc 'Create test databases'
  task 'create' do
    target_database_servers.create_databases
  end

  desc 'Drop test databases'
  task 'drop' do
    target_database_servers.drop_databases
  end

end
