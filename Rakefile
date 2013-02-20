# encoding: utf-8

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

$:.unshift(File.dirname(__FILE__) + '/lib')
Dir['rake_tasks/**/*.rake'].sort.each { |path| load path }

require File.expand_path('spec/lib/target_database_servers',
                         File.dirname(__FILE__))
