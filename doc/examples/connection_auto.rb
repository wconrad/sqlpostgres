#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "../../lib/")

require 'sqlpostgres'
include SqlPostgres

dbName = "sqlpostgres_test"
Connection.open do |connection1|
  connection1.exec("create database #{dbName}")
  begin
    # Example: ../manual.dbk
    Connection.open('db_name'=>'sqlpostgres_test') do |connection|
      # Use the connection
    end
    # End example
    sleep(0.1)     # I don't know why, but it seems to take some time
    # for the connection to be closed
  ensure
    connection1.exec("drop database #{dbName}")
  end
end
