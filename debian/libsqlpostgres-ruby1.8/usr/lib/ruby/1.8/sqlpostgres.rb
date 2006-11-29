# sqlpostgres is a wrapper around the venerable Ruby postgres library.
# sqlpostgres builds and executes insert, update and select
# statements.  sqlpostgres statements are easier to read and maintain
# than raw SQL.  Ruby data types are automatically converted to and
# from SQL data types, and results are returned as an array of hashes
# rather than an array of arrays.
#
# Here's a small example showing some inserts, an update, and a
# select:
#
#** Example: simple
#   require "sqlpostgres"
#   
#   include SqlPostgres
#   
#   Connection.open do |connection|
#     connection.exec("create temporary table foo (t text)")
#     
#     insert = Insert.new('foo', connection)
#     insert.insert('t', 'Smith')
#     insert.exec
#     
#     insert = Insert.new('foo', connection)
#     insert.insert('t', 'Jones')
#     insert.exec
#     
#     update = Update.new('foo', connection)
#     update.set('t', "O'Brien")
#     update.where(["t = %s", "Smith"])
#     update.exec  
#     
#     select = Select.new(connection)
#     select.select('t')
#     select.from('foo')
#     select.order_by('t')
#     p select.exec  # [{"t"=>"Jones"}, {"t"=>"O'Brien"}]
#     
#   end
#**
#
# All classes and functions in this library are in the SqlPostgres module.
# Users of this library should either use the module name as a prefix:
#
#** Example: use_prefix
#   require 'sqlpostgres'
#   insert = SqlPostgres::Insert.new('foo')
#**
#
# or include the module:
#
#** Example: include_module
#   require 'sqlpostgres'
#   include SqlPostgres
#   insert = Insert.new('foo')
#**

for path in Dir[File.join(File.dirname(__FILE__), 'sqlpostgres', '*.rb')]
  require File.expand_path(path)
end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
