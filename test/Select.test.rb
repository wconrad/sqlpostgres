#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'
require 'date'

# Much of Select is tested in the "roundtrip" test.

class SelectTest < Test

  include SqlPostgres
  include TestUtil

  def test
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      select = Select.new(connection)
      select.select('i')
      select.from(table1)
      select.order_by('i')
      assertEquals(select.statement, "select i from #{table1} order by i")
      assertEquals(select.exec, [])
      connection.exec("insert into #{table1} (i) values (1)")
      assertEquals(select.exec, [{'i' => 1}])
      connection.exec("insert into #{table1} (i) values (2)")
      assertEquals(select.exec, [{'i' => 1}, {'i' => 2}])
    end
  end

  def testDefaultConnection
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      setDefaultConnection(connection) do
        select = Select.new(connection)
        select.select('i')
        select.from(table1)
        assertEquals(select.exec, [{'i'=>1}])
      end
    end
  end

  def testGiveConnectionToExec
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      setDefaultConnection(connection) do
        select = Select.new
        select.select('i')
        select.from(table1)
        assertEquals(select.exec(connection), [{'i'=>1}])
      end
    end
  end

  def testOrderBy
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int, j int, k int)")
      connection.exec("insert into #{table1} values (0, 0, 0)")
      connection.exec("insert into #{table1} values (0, 0, 1)")
      connection.exec("insert into #{table1} values (0, 1, 0)")
      connection.exec("insert into #{table1} values (0, 1, 1)")
      connection.exec("insert into #{table1} values (1, 0, 0)")
      connection.exec("insert into #{table1} values (1, 0, 1)")
      connection.exec("insert into #{table1} values (1, 1, 0)")
      connection.exec("insert into #{table1} values (1, 1, 1)")
      select = Select.new(connection)
      select.select("i")
      select.select("j")
      select.select("k")
      select.from(table1)
      select.order_by('i')
      select.order_by('j', 'asc')
      select.order_by('k', 'desc')
      assertEquals(select.statement, 
                   "select i, j, k from #{table1} order by i, j asc, k desc")
      assertEquals(select.exec, [
                     {'i'=>0, 'j'=>0, 'k'=>1},
                     {'i'=>0, 'j'=>0, 'k'=>0},
                     {'i'=>0, 'j'=>1, 'k'=>1},
                     {'i'=>0, 'j'=>1, 'k'=>0},
                     {'i'=>1, 'j'=>0, 'k'=>1},
                     {'i'=>1, 'j'=>0, 'k'=>0},
                     {'i'=>1, 'j'=>1, 'k'=>1},
                     {'i'=>1, 'j'=>1, 'k'=>0},
                   ])
    end
  end

  def testOrderBy_ArbitraryExpression
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (t text)")
      connection.exec("insert into #{table1} values ('aaa')")
      connection.exec("insert into #{table1} values ('bb')")
      connection.exec("insert into #{table1} values ('c')")
      select = Select.new(connection)
      select.select('t')
      select.from(table1)
      select.order_by('char_length(t)')
      assertEquals(select.statement,
                   "select t from #{table1} order by char_length(t)")
      assertEquals(select.exec, [{'t'=>'c'}, {'t'=>'bb'}, {'t'=>'aaa'}])
    end
  end

  def testOrderBy_ExpressionWithSubstitution
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (t text)")
      connection.exec("insert into #{table1} values ('a')")
      connection.exec("insert into #{table1} values ('b')")
      connection.exec("insert into #{table1} values ('c')")
      select = Select.new(connection)
      select.select('t')
      select.from(table1)
      select.order_by(['case when t = %s then %s else t end', 'b', '0'])
      assertEquals(select.statement,
                   "select t from #{table1} order by "\
                   "case when t = 'b' then '0' else t end")
      assertEquals(select.exec, [{'t'=>'b'}, {'t'=>'a'}, {'t'=>'c'}])
    end
  end

  def testSelectInteger_Expression
    makeTestConnection do |connection|
      select = Select.new(connection)
      select.select(["%s * 2", 2], 'double')
      assertEquals(select.statement, "select 2 * 2 as double")
      assertEquals(select.exec, [{'double'=>4}])
    end
  end
  
  def testSelectFloat_Expression
    makeTestConnection do |connection|
      select = Select.new(connection)
      select.select(["%s * 2", 1.414], 'double')
      assertEquals(select.statement, "select 1.414 * 2 as double")
      assertEquals(select.exec, [{'double'=>2.828}])
    end
  end

  def testSelectString_Expression
    makeTestConnection do |connection|
      select = Select.new(connection)
      select.select(["%s || %s", "Fred's", " Place"], 'title')
      assertEquals(select.statement, 
                   %q"select 'Fred\\047s' || ' Place' as title")
      assertEquals(select.exec, [{'title'=>"Fred's Place"}])
    end
  end
  
  def testSelectTime_Expression
    makeTestConnection do |connection|
      now = Time.local(2001, 1, 1)
      select = Select.new(connection)
      select.select(
                    [
                      "%s + %s",  
                      PgTime.new(12, 0, 0),
                      PgInterval.new('hours'=>1)
                    ], 
                    'later')
      assertEquals(select.exec, [{'later'=>PgTime.new(13, 0, 0)}])
    end
  end

  def testSelectBoolean_Expression
    makeTestConnection do |connection|
      select = Select.new(connection)
      select.select(["not %s", false], 'opposite')
      assertEquals(select.statement, "select not false as opposite")
      assertEquals(select.exec, [{'opposite'=>true}])
    end
  end

  def test_select_literal
    values = [
      "Fool's errand",
      1,
      -9223372036854775808, 
      +9223372036854775807,
      1.414,
      1e290,
      true,
      false,
      PgTime.new(23, 59, 59),
      nil,
      PgInterval.new('days'=>1),
      PgTime.new(12, 0, 0),
      PgTimeWithTimeZone.new(12, 0, 0, -8, 0),
      PgTimestamp.new(2001, 1, 1, 12, 0, 0),
      PgPoint.new(1, 2),
      PgLineSegment.new(0, 1, 2, 3),
      PgBox.new(3, 4, 1, 2),
      PgPath.new(true, PgPoint.new(1, 2), PgPoint.new(3, 4)),
      PgPolygon.new(PgPoint.new(1, 2), PgPoint.new(3, 4)),
      PgCircle.new(1, 2, 3),
      PgBit.new("010101"),
      PgInet.new("1.2.0.0/16"),
      PgCidr.new("1.2.3.0/24"),
      PgMacAddr.new("08:00:2b:01:02:03"),
    ]
    makeTestConnection do |connection|
      for value in values
        assertInfo("For value #{value.inspect}") do

          select = Select.new(connection)
          select.select_literal(value)
          assertEquals(select.statement, 
                       "select #{Translate.escape_sql(value)}")

          select = Select.new(connection)
          select.select_literal(value, 'v')
          assertEquals(select.exec, [{'v'=>value}])

        end
      end
    end
  end

  def testSelectExpression
    makeTestConnection do |connection|
      select = Select.new(connection)
      select.select(["%s || %s || %s", "Cat", " ", "Dog"], 'animal')
      assertEquals(select.statement, "select 'Cat' || ' ' || 'Dog' as animal")
      assertEquals(select.exec, [{'animal'=>'Cat Dog'}])
    end
  end

  def testUserConversion
    makeTestConnection do |connection|
      select = Select.new(connection)
      select.select(["%s", "abc"], 'letters') do |s|
        s.scan(/./)
      end
      assertEquals(select.exec, [{'letters'=>['a', 'b', 'c']}])
    end
  end

  def testWhere
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table1} values (3)")
      select = Select.new(connection)
      select.select('i')
      select.from(table1)
      select.where("i = 1")
      assertEquals(select.statement, "select i from #{table1} where i = 1")
      assertEquals(select.exec, [{'i'=>1}])
    end
  end

  def testWhere_Multiple
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table1} values (3)")
      select = Select.new(connection)
      select.select('i')
      select.from(table1)
      select.where("i > 1")
      select.where("i < 3")
      assertEquals(select.statement, 
                   "select i from #{table1} where i > 1 and i < 3")
      assertEquals(select.exec, [{'i'=>2}])
    end
  end

  def testWhere_WithValues
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (t text)")
      connection.exec("insert into #{table1} values ('bar')")
      connection.exec("insert into #{table1} values ('baz')")
      select = Select.new(connection)
      select.select('t')
      select.from(table1)
      select.where(["t = %s", 'bar'])
      assertEquals(select.statement, "select t from #{table1} where t = 'bar'")
      assertEquals(select.exec, [{'t'=>'bar'}])
    end
  end

  def testSelectSubselect
    makeTestConnection do |connection|
      time = PgTime.new(12, 0, 0)
      select1 = Select.new
      select1.select_literal(1)
      select2 = Select.new
      select2.select_literal(time)
      select3 = Select.new(connection)
      select3.select(select1, 'i')
      select3.select(select2, 't')
      assertEquals(select3.exec, [{'i'=>1, 't'=>time}])
    end
  end

  def testFromAlias
    select = Select.new
    select.select('i')
    select.from('foo', 'bar')
    assertEquals(select.statement, "select i from foo as bar")
  end

  def testFromSubselect
    makeTestConnection do |connection|
      time = Time.now
      select1 = Select.new
      select1.select_literal(1, 'i')
      select2 = Select.new(connection)
      select2.select('i')
      select2.from(select1, 'foo')
      assertEquals(select2.statement, "select i from (select 1 as i) as foo")
      assertEquals(select2.exec, [{'i'=>1}])
    end
  end

  def testNoConnection
    select = Select.new
    assertException(NoConnection) do
      select.exec
    end
  end

  def testGroupBy
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int, j int)")
      1.times do connection.exec("insert into #{table1} values (0, 0)") end
      2.times do connection.exec("insert into #{table1} values (0, 1)") end
      3.times do connection.exec("insert into #{table1} values (1, 0)") end
      4.times do connection.exec("insert into #{table1} values (1, 1)") end
      select = Select.new(connection)
      select.select('i')
      select.select('j')
      select.select('count(*)', 'count')
      select.from(table1)
      select.group_by('i')
      select.group_by('j')
      select.order_by('i')
      select.order_by('j')
      assertEquals(select.statement, 
                   "select i, j, count(*) as count from #{table1} "\
                   "group by i, j order by i, j")
      assertEquals(select.exec,
                   [
                     {"i"=>0, "j"=>0, "count"=>1}, 
                     {"i"=>0, "j"=>1, "count"=>2}, 
                     {"i"=>1, "j"=>0, "count"=>3}, 
                     {"i"=>1, "j"=>1, "count"=>4}
                   ])
    end
  end

  def testGroupBy_Expression
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (t text)")
      connection.exec("insert into #{table1} values ('alpha')")
      connection.exec("insert into #{table1} values ('beta')")
      connection.exec("insert into #{table1} values ('gamma')")
      select = Select.new(connection)
      select.select('count(*)', 'count')
      select.from(table1)
      select.group_by(['case t when %s then 0 else 1 end', 'alpha'])
      select.order_by('count')
      assertEquals(select.exec, [{'count'=>1}, {'count'=>2}])
    end
  end

  def testHaving
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (0)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table1} values (2)")
      select = Select.new(connection)
      select.select('count(*)', 'count')
      select.from(table1)
      select.group_by('i')
      select.having('count(*) > 1')
      select.having('count(*) < 3')
      assertEquals(select.exec, [{'count'=>2}])
    end
  end

  def testHaving_Expression
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (0)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (1)")
      select = Select.new(connection)
      select.select('count(*)', 'count')
      select.from(table1)
      select.group_by('i')
      select.having(['count(*) > %s', 1])
      assertEquals(select.exec, [{'count'=>2}])
    end
  end

  def testCrossJoin
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (i int)")
      connection.exec("insert into #{table1} (i) values (1)")
      connection.exec("insert into #{table1} (i) values (2)")
      connection.exec("insert into #{table2} (i) values (3)")
      connection.exec("insert into #{table2} (i) values (4)")
      select = Select.new(connection)
      select.select("#{table1}.i", "i1")
      select.select("#{table2}.i", "i2")
      select.from(table1)
      select.cross_join(table2)
      select.order_by('i1')
      select.order_by('i2')
      assertEquals(select.statement, 
                   "select #{table1}.i as i1, #{table2}.i as i2 "\
                   "from #{table1} cross join #{table2} "\
                   "order by i1, i2")
      assertEquals(select.exec, [
                     {"i1"=>1, "i2"=>3}, 
                     {"i1"=>1, "i2"=>4}, 
                     {"i1"=>2, "i2"=>3}, 
                     {"i1"=>2, "i2"=>4}
                   ])
    end
  end

  def testNaturalJoin
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (i int)")
      connection.exec("insert into #{table1} (i) values (1)")
      connection.exec("insert into #{table1} (i) values (2)")
      connection.exec("insert into #{table2} (i) values (2)")
      connection.exec("insert into #{table2} (i) values (3)")
      select = Select.new(connection)
      select.select("i")
      select.from(table1)
      select.natural_join(table2)
      assertEquals(select.statement, 
                   "select i from #{table1} natural join #{table2}")
      assertEquals(select.exec, [{'i'=>2}])
    end
  end

  def testNaturalJoin_ThreeTables
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (i int)")
      connection.exec("create temporary table #{table3} (i int)")
      connection.exec("insert into #{table1} (i) values (1)")
      connection.exec("insert into #{table1} (i) values (2)")
      connection.exec("insert into #{table1} (i) values (3)")
      connection.exec("insert into #{table2} (i) values (2)")
      connection.exec("insert into #{table2} (i) values (3)")
      connection.exec("insert into #{table3} (i) values (1)")
      connection.exec("insert into #{table3} (i) values (2)")
      select = Select.new(connection)
      select.select("i")
      select.from(table1)
      select.natural_join(table2)
      select.natural_join(table3)
      assertEquals(select.statement, 
                   "select i from #{table1} natural join #{table2} "\
                   "natural join #{table3}")
      assertEquals(select.exec, [{'i'=>2}])
    end
  end

  def testJoinUsing
    testCases = [
      [
        "inner",
        [
          {'i1'=>2, 'i2'=>2},
        ]
      ],
      [
        "left outer",
        [
          {'i1'=>1, 'i2'=>nil},
          {'i1'=>2, 'i2'=>2},
        ]
      ],
      [
        "right outer",
        [
          {'i1'=>2, 'i2'=>2},
          {'i1'=>nil, 'i2'=>3},
        ]
      ],
      [
        "full outer",
        [
          {'i1'=>1, 'i2'=>nil},
          {'i1'=>2, 'i2'=>2},
          {'i1'=>nil, 'i2'=>3},
        ]
      ],
    ]
    for joinType, result in testCases
      assertInfo("For joinType=#{joinType.inspect}") do
        makeTestConnection do |connection|
          connection.exec("create temporary table #{table1} (i int)")
          connection.exec("create temporary table #{table2} (i int)")
          connection.exec("insert into #{table1} (i) values (1)")
          connection.exec("insert into #{table1} (i) values (2)")
          connection.exec("insert into #{table2} (i) values (2)")
          connection.exec("insert into #{table2} (i) values (3)")
          select = Select.new(connection)
          select.select("#{table1}.i", 'i1')
          select.select("#{table2}.i", 'i2')
          select.from(table1)
          select.join_using(joinType, table2, 'i')
          select.order_by('i1')
          select.order_by('i2')
          assertEquals(select.statement, 
                       "select #{table1}.i as i1, #{table2}.i as i2 "\
                       "from #{table1} #{joinType} join #{table2} "\
                       "using (i) order by i1, i2")
          assertEquals(select.exec, result)
        end
      end
    end
  end

  def testJoinUsing_MultipleColumns
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int, j int)")
      connection.exec("create temporary table #{table2} (i int, j int)")
      connection.exec("insert into #{table1} (i, j) values (1, 1)")
      connection.exec("insert into #{table1} (i, j) values (1, 2)")
      connection.exec("insert into #{table2} (i, j) values (1, 2)")
      connection.exec("insert into #{table2} (i, j) values (2, 2)")
      select = Select.new(connection)
      select.select("i")
      select.select("j")
      select.from(table1)
      select.join_using('inner', table2, 'i', 'j')
      assertEquals(select.statement, 
                   "select i, j from #{table1} inner join #{table2} "\
                   "using (i, j)")
      assertEquals(select.exec, [{'i'=>1, 'j'=>2}])
    end
  end

  def testJoinOn
    testCases = [
      [
        "inner", 
        [
          {"i"=>2, "j"=>2}
        ]
      ],
      [
        "left outer", 
        [
          {"i"=>1, "j"=>nil}, 
          {"i"=>2, 'j'=>2}
        ]
      ],
      [
        "right outer", 
        [
          {"i"=>2, "j"=>2}, 
          {"i"=>nil, 'j'=>3}
        ]
      ],
      [
        "full outer", 
        [
          {"i"=>1, "j"=>nil}, 
          {"i"=>2, "j"=>2}, 
          {"i"=>nil, 'j'=>3}
        ]
      ],
    ]
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (j int)")
      connection.exec("insert into #{table1} (i) values (1)")
      connection.exec("insert into #{table1} (i) values (2)")
      connection.exec("insert into #{table2} (j) values (2)")
      connection.exec("insert into #{table2} (j) values (3)")
      for joinType, result in testCases
        assertInfo("for joinType=#{joinType.inspect}") do
          select = Select.new(connection)
          select.select("i")
          select.select("j")
          select.from(table1)
          select.join_on(joinType, table2, 'i = j')
          select.order_by('i')
          select.order_by('j')
          assertEquals(select.statement, 
                       "select i, j from #{table1} "\
                       "#{joinType} join #{table2} on (i = j) "\
                       "order by i, j")
          assertEquals(select.exec, result)
        end
      end
    end
  end

  def testJoinOn_SubstituteValues
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (j int)")
      connection.exec("insert into #{table1} (i) values (1)")
      connection.exec("insert into #{table1} (i) values (2)")
      connection.exec("insert into #{table2} (j) values (1)")
      connection.exec("insert into #{table2} (j) values (2)")
      connection.exec("insert into #{table2} (j) values (3)")
      select = Select.new(connection)
      select.select("i")
      select.select("j")
      select.from(table1)
      select.join_on('inner', table2, ['i = j and i > %s', 1])
      assertEquals(select.statement, 
                   "select i, j from #{table1} "\
                   "inner join #{table2} on (i = j and i > 1)")
      assertEquals(select.exec, [{'i'=>2, 'j'=>2}])
    end
  end

  def testLimit
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table1} values (3)")
      select = Select.new(connection)
      select.select('i')
      select.from(table1)
      select.order_by('i')
      select.limit(2)
      assertEquals(select.statement, 
                   "select i from #{table1} order by i limit 2")
      assertEquals(select.exec, [{'i'=>1}, {'i'=>2}])
    end
  end

  def testOffset
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table1} values (3)")
      select = Select.new(connection)
      select.select('i')
      select.from(table1)
      select.order_by('i')
      select.limit(1)
      select.offset(1)
      assertEquals(select.statement, 
                   "select i from #{table1} order by i limit 1 offset 1")
      assertEquals(select.exec, [{'i'=>2}])
    end
  end

  def testDistinct
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      select = Select.new(connection)
      select.distinct
      select.select('i')
      select.from(table1)
      select.order_by('i')
      assertEquals(select.statement,
                   "select distinct i from #{table1} order by i")
      assertEquals(select.exec, [{'i'=>1}, {'i'=>2}])
    end
  end

  def testDistinctOn
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int, j int, k int)")
      connection.exec("insert into #{table1} values (0, 0, 0)")
      connection.exec("insert into #{table1} values (0, 0, 1)")
      connection.exec("insert into #{table1} values (0, 1, 0)")
      connection.exec("insert into #{table1} values (0, 1, 1)")
      connection.exec("insert into #{table1} values (1, 0, 0)")
      connection.exec("insert into #{table1} values (1, 0, 1)")
      connection.exec("insert into #{table1} values (1, 1, 0)")
      connection.exec("insert into #{table1} values (1, 1, 1)")
      select = Select.new(connection)
      select.distinct_on('i')
      select.select('i')
      select.select('j')
      select.select('k')
      select.from(table1)
      select.order_by('i')
      select.order_by('j')
      select.order_by('k')
      assertEquals(select.statement,
                   "select distinct on (i) i, j, k from #{table1} "\
                   "order by i, j, k")
      assertEquals(select.exec, [
                     {"i"=>0, "j"=>0, "k"=>0}, 
                     {"i"=>1, "j"=>0, "k"=>0}
                   ])
    end
  end

  def testDistinctOn_TwoColumns
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int, j int, k int)")
      connection.exec("insert into #{table1} values (0, 0, 0)")
      connection.exec("insert into #{table1} values (0, 0, 1)")
      connection.exec("insert into #{table1} values (0, 1, 0)")
      connection.exec("insert into #{table1} values (0, 1, 1)")
      connection.exec("insert into #{table1} values (1, 0, 0)")
      connection.exec("insert into #{table1} values (1, 0, 1)")
      connection.exec("insert into #{table1} values (1, 1, 0)")
      connection.exec("insert into #{table1} values (1, 1, 1)")
      select = Select.new(connection)
      select.distinct_on('i')
      select.distinct_on('j')
      select.select('i')
      select.select('j')
      select.select('k')
      select.from(table1)
      select.order_by('i')
      select.order_by('j')
      select.order_by('k')
      assertEquals(select.statement,
                   "select distinct on (i, j) i, j, k from #{table1} "\
                   "order by i, j, k")
      assertEquals(select.exec, [
                     {"i"=>0, "j"=>0, "k"=>0}, 
                     {"i"=>0, "j"=>1, "k"=>0}, 
                     {"i"=>1, "j"=>0, "k"=>0},
                     {"i"=>1, "j"=>1, "k"=>0},
                   ])
    end
  end

  def testSetOps
    testCases = [
      [:union, 'union', [1, 2, 3, 4]],
      [:union_all, 'union all', [1, 1, 2, 2, 3, 3, 3, 3, 4]],
      [:intersect, 'intersect', [2, 3]],
      [:intersect_all, 'intersect all', [2, 3, 3]],
      [:except, 'except', [1]],
      [:except_all, 'except all', [1, 1]],
    ]
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table1} values (3)")
      connection.exec("insert into #{table1} values (3)")
      connection.exec("insert into #{table2} values (2)")
      connection.exec("insert into #{table2} values (3)")
      connection.exec("insert into #{table2} values (3)")
      connection.exec("insert into #{table2} values (4)")
      subselect = Select.new
      subselect.select('i')
      subselect.from(table2)
      for function, op, expectedValues in testCases
        assertInfo("For function #{function}:") do
          select = Select.new(connection)
          select.select('i')
          select.from(table1)
          select.send(function, subselect)
          select.order_by('i')
          assertEquals(select.statement, "select i from #{table1} "\
                       "#{op} (select i from #{table2}) order by i")
          expectedResult = expectedValues.collect do |i| {'i'=>i} end
          assertEquals(select.exec, expectedResult)
        end
      end
    end
  end

  def testMultipleSetOps
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (i int)")
      connection.exec("create temporary table #{table3} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table2} values (1)")
      connection.exec("insert into #{table3} values (1)")
      subselect2 = Select.new
      subselect2.select('i')
      subselect2.from(table2)
      subselect3 = Select.new
      subselect3.select('i')
      subselect3.from(table3)
      select = Select.new(connection)
      select.select('i')
      select.from(table1)
      select.except(subselect2)
      select.union(subselect3)
      select.order_by('i')
      assertEquals(select.statement, "select i from #{table1} "\
                   "except (select i from #{table2}) "\
                   "union (select i from #{table3}) order by i")
      assertEquals(select.exec, [{'i'=>1}, {'i'=>2}])
    end
  end

  def testUnionWithWhereClause
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      10.downto(1) do |i|
        connection.exec("insert into #{table1} values (#{i})")
      end
      sql1 = Select.new
      sql1.select('i')
      sql1.from(table1)
      sql1.where('i % 2 = 0')
      sql2 = Select.new(connection)
      sql2.select('i')
      sql2.from(table1)
      sql2.where('i % 1 = 0')
      sql2.union(sql1)
      sql3 = Select.new(connection)
      sql3.select('i')
      sql3.from(sql2, 'foo')
      sql3.order_by('i')
      values = sql3.exec.collect do |row|
        row['i']
      end
      assertEquals(values, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    end
  end

  def testMultipleSetOps_Nested
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (i int)")
      connection.exec("create temporary table #{table3} (i int)")
      connection.exec("insert into #{table1} values (1)")
      connection.exec("insert into #{table1} values (2)")
      connection.exec("insert into #{table2} values (1)")
      connection.exec("insert into #{table3} values (1)")
      subselect3 = Select.new
      subselect3.select('i')
      subselect3.from(table3)
      subselect2 = Select.new
      subselect2.select('i')
      subselect2.union(subselect3)
      subselect2.from(table2)
      select = Select.new(connection)
      select.select('i')
      select.from(table1)
      select.except(subselect2)
      select.order_by('i')
      assertEquals(select.statement, "select i from #{table1} "\
                   "except (select i from #{table2} "\
                   "union (select i from #{table3})) order by i")
      assertEquals(select.exec, [{'i'=>2}])
    end
  end

  def testWhereIn
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      for i in (0..9)
        insert = Insert.new(table1, connection)
        insert.insert('i', i)
        insert.exec
      end
      select = Select.new(connection)
      select.select('i')
      select.from(table1)
      select.where(['i in %s', [:in, 2, 4]])
      assertEquals(select.exec, [{'i'=>2}, {'i'=>4}])
    end
  end

  def testForUpdate
    makeTestConnection do |db1|
      db1.exec("create temporary table #{table1} (i int)")
      db1.exec("insert into #{table1} (i) values (1)")
      db1.exec("begin")
      sql = Select.new(db1)
      sql.select('i')
      sql.from(table1)
      sql.where(['i = %s', 1])
      sql.for_update
      assertEquals(sql.exec, [{'i'=>1}])
    end
  end

end

SelectTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
