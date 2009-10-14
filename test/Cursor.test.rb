#!/usr/bin/ruby1.8

$:.unshift(File.dirname(__FILE__))
require 'TestSetup'

require 'MockPGconn'

class CursorTest < Test

  include SqlPostgres
  include TestUtil

  def testBasic
    cursor_setup do |connection|
      Transaction.new(connection) do
        sql = Select.new
        sql.select('i')
        sql.from(table1)
        cursor = Cursor.new('cursor1', sql, {}, connection)
        assertEquals(cursor.fetch, [{'i'=>0}])
        assertEquals(cursor.fetch, [{'i'=>1}])
        assertEquals(cursor.fetch, [{'i'=>2}])
        assertEquals(cursor.fetch, [{'i'=>3}])
        assertEquals(cursor.fetch, [{'i'=>4}])
        assertEquals(cursor.fetch, [])
        cursor.close
      end
    end
  end

  def testInitWithClosure
    cursor_setup do |connection|
      Transaction.new(connection) do
        sql = Select.new
        sql.select('i')
        sql.from(table1)
        Cursor.new('cursor1', sql, {}, connection) do |cursor|
          assertEquals(cursor.fetch, [{'i'=>0}])
        end
      end
    end
  end

  def test_fetch_count
    cursor_setup do |connection|
      Transaction.new(connection) do
        sql = Select.new
        sql.select('i')
        sql.from(table1)
        cursor = Cursor.new('cursor1', sql, {}, connection)
        assertEquals(cursor.fetch(2), [{'i'=>0}, {'i'=>1}])
        assertEquals(cursor.fetch(2), [{'i'=>2}, {'i'=>3}])
        assertEquals(cursor.fetch(2), [{'i'=>4}])
        assertEquals(cursor.fetch(2), [])
        cursor.close
      end
    end
  end

  def testHold
    cursor_setup do |connection|
      cursor = nil
      Transaction.new(connection) do
        sql = Select.new
        sql.select('i')
        sql.from(table1)
        cursor = Cursor.new('cursor1', sql, {:hold=>true}, connection)
      end
      assertEquals(cursor.fetch, [{'i'=>0}])
      cursor.close
    end
  end

  def testDefaultHold
    cursor_setup do |connection|
      cursor = nil
      Transaction.new(connection) do
        sql = Select.new
        sql.select('i')
        sql.from(table1)
        cursor = Cursor.new('cursor1', sql, {}, connection)
      end
      assertException(PGError, /cursor "cursor1" does not exist/)do
        assertEquals(cursor.fetch, [{'i'=>0}])
      end
    end
  end

  def testNoHold
    cursor_setup do |connection|
      cursor = nil
      Transaction.new(connection) do
        sql = Select.new
        sql.select('i')
        sql.from(table1)
        cursor = Cursor.new('cursor1', sql, {:hold=>false}, connection)
      end
      assertException(PGError, /cursor "cursor1" does not exist/)do
        assertEquals(cursor.fetch, [{'i'=>0}])
      end
    end
  end

  def testNoScroll
    cursor_setup do |connection|
      cursor = nil
      Transaction.new(connection) do
        sql = select_too_complex_for_backwards_fetch_without_scroll_option
        cursor = Cursor.new('cursor1', sql, {:scroll=>false}, connection)
        assertException(PGError, /cursor can only scan forward/) do
          cursor.fetch('PRIOR')
        end
      end
    end
  end

  def testScroll
    cursor_setup do |connection|
      Transaction.new(connection) do
        sql = select_too_complex_for_backwards_fetch_without_scroll_option
        Cursor.new('cursor1', sql, {:scroll=>true}, connection) do |cursor|
          assertEquals(cursor.fetch, [{'i'=>0}])
          assertEquals(cursor.fetch, [{'i'=>2}])
          assertEquals(cursor.fetch('PRIOR'), [{'i'=>0}])
          assertEquals(cursor.fetch('PRIOR'), [])
        end
      end
    end
  end

  def testDefaultScroll
    cursor_setup do |connection|
      Transaction.new(connection) do
        sql = select_too_complex_for_backwards_fetch_without_scroll_option
        cursor = Cursor.new('cursor1', sql, {}, connection)
        assertException(PGError, /cursor can only scan forward/) do
          cursor.fetch('PRIOR')
        end
      end
    end
  end

  def testMove
    cursor_setup do |connection|
      Transaction.new(connection) do
        sql = Select.new
        sql.select('i')
        sql.from(table1)
        Cursor.new('cursor1', sql, {}, connection) do |cursor|
          cursor.move("absolute 2")
          assertEquals(cursor.fetch, [{'i'=>2}])
        end
      end
    end
  end

  private

  def select_too_complex_for_backwards_fetch_without_scroll_option
    sql = Select.new
    sql.select('i')
    sql.from(table1)
    sql.join_using('inner', table2, 'i')
    sql.where('i % 2 = 0')
    sql
  end

  def cursor_setup
    makeTestConnection do |connection|
      connection.exec("create temporary table #{table1} (i int)")
      connection.exec("create temporary table #{table2} (i int)")
      5.times do |i|
        connection.exec("insert into #{table1} values (#{i})")
        connection.exec("insert into #{table2} values (#{i})")
      end
        yield(connection)
    end
  end

end

CursorTest.new.run if $0 == __FILE__

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
