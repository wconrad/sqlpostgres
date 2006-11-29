#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'

class UpdateTest < Test

  include SqlPostgres
  include TestUtil

  def testBasicUpdate
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      update = Update.new(table1, connection)
      update.set('i', 0)
      assertEquals(update.statement, "update #{table1} set i = 0")
      update.exec
      assertEquals(connection.query("select * from #{table1}"),
                   [["0"], ["0"]])
    end
  end

  def testDefaultConnection
    makeTestConnection do |connection|
      setDefaultConnection(connection) do
        connection.exec("create temporary table #{table1} (i int)")
        connection.exec("insert into #{table1} values (1)")
        connection.exec("insert into #{table1} values (2)")
        update = Update.new(table1)
        update.set('i', 0)
        assertEquals(update.statement, "update #{table1} set i = 0")
        update.exec
        assertEquals(connection.query("select * from #{table1}"),
                     [["0"], ["0"]])
      end
    end
  end

  def testExec_Connection
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      update = Update.new(table1)
      update.set('i', 0)
      assertEquals(update.statement, "update #{table1} set i = 0")
      update.exec(connection)
      assertEquals(connection.query("select * from #{table1}"),
                   [["0"], ["0"]])
    end
  end

  def testWhere
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      update = Update.new(table1, connection)
      update.set('i', 3)
      update.where('i = 2')
      assertEquals(update.statement, "update #{table1} set i = 3 where i = 2")
      update.exec
      rows = connection.query("select * from #{table1} order by i")
      assertEquals(rows, [["1"], ["3"]])
    end
  end

  def testWhere_Substitution
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (t text)")
      connection.exec("insert into #{table1} values ('Smith')")
      connection.exec("insert into #{table1} values ('O\\'Brien')")
      update = Update.new(table1, connection)
      update.set('t', 'Tam')
      update.where(['t = %s', "O'Brien"])
      assertEquals(update.statement, "update #{table1} set t = 'Tam' "\
                   "where t = 'O\\047Brien'")
      update.exec
      rows = connection.query("select * from #{table1} order by t")
      assertEquals(rows, [["Smith"], ["Tam"]])
    end
  end

  def testWhere_Multiple
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table1} values (3)")
      update = Update.new(table1, connection)
      update.set('i', -2)
      update.where('i > 1')
      update.where('i < 3')
      assertEquals(update.statement, "update #{table1} set i = -2 "\
                   "where i > 1 and i < 3")
      update.exec
      rows = connection.query("select * from #{table1} order by i")
      assertEquals(rows, [["-2"], ["1"], ["3"]])
    end
  end

  def testSet
    time = Time.now
    testCases = [
      ["int", -1, "-1"],
      ["int", 1, "1"],
      ["int", nil, nil],
      ["text", "foo", "foo"],
      ["text", "It's", "It's"],
      ["text", nil, nil],
      ["real", 3.14, "3.14"],
      ["real", nil, nil],
      ["timestamp", time, Translate.timeToSql(time).chomp('0').chomp('0')],
      ["timestamp", nil, nil],
      ["boolean", false, "f"],
      ["boolean", true, "t"],
      ["boolean", nil, nil],
    ]
    makeTestConnection do |connection|
      for columnType, value, string in testCases
        connection.exec("create temporary table #{table1} (v #{columnType})")
        connection.exec("insert into #{table1} (v) values (null)")
        update = Update.new(table1, connection)
        update.set('v', value)
        update.exec
        assertEquals(connection.query("select v from #{table1}"),
                     [[string]])
        connection.exec("drop table #{table1}")
      end
    end
  end

  def testSet_Subquery
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (i int, j int)")
      connection.exec("insert into #{table1} (i) values (1)")
      connection.exec("insert into #{table1} (i) values (2)")
      connection.exec("insert into #{table2} (i, j) values (1, -1)")
      connection.exec("insert into #{table2} (i, j) values (2, -2)")
      select = Select.new
      select.select('j')
      select.from(table2)
      select.where(["i = #{table1}.i"])
      update = Update.new(table1, connection)
      update.set('i', select)
      update.exec
      assertEquals(update.statement, "update #{table1} "\
                   "set i = (select j from #{table2} where i = #{table1}.i)")
      rows = connection.query("select i from #{table1} order by i")
      assertEquals(rows, [["-2"], ["-1"]])
    end
  end

  def testSetExpression
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (i int, j int)")
      connection.exec("insert into #{table1} (i) values (1)")
      connection.exec("insert into #{table1} (i) values (2)")
      update = Update.new(table1, connection)
      update.set('i', ['i + 1'])
      update.exec
      assertEquals(update.statement, "update #{table1} set i = i + 1")
      rows = connection.query("select i from #{table1} order by i")
      assertEquals(rows, [["2"], ["3"]])
    end
  end

  def testSetArray
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int[])")
      connection.exec("insert into #{table1} (i) values ('{}')")
      update = Update.new(table1, connection)
      update.set_array('i', [1, 2, 3])
      update.exec
      rows = connection.query("select i from #{table1} order by i")
      assertEquals(rows, [["{1,2,3}"]])
    end
  end

  def testOnly
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (j int) "\
                      "inherits(#{table1})")
      connection.exec("insert into #{table1} (i) values (1)")
      connection.exec("insert into #{table2} (i) values (2)")
      update = Update.new(table1, connection)
      update.only
      update.set('i', 0)
      assertEquals(update.statement, "update only #{table1} set i = 0")
      update.exec
      rows = connection.query("select i from #{table1} order by i")
      assertEquals(rows, [["0"], ["2"]])
    end
  end

  def testSetBytea
    makeTestConnection do |connection|
      expected = allCharacters
      connection.exec("create temporary table #{table1} (b bytea)")
      connection.exec("insert into #{table1} (b) values (NULL)")
      update = Update.new(table1, connection)
      update.set_bytea('b', expected)
      update.exec
      sql = Select.new(connection)
      sql.select('b')
      sql.from(table1)
      actual = sql.exec.first['b']
      assertEquals(actual, expected)
    end
  end

end

UpdateTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
