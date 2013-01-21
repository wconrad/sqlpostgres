require File.expand_path('spec_helper', File.dirname(__FILE__))

module SqlPostgres

  describe Cursor do

    CURSOR_DOES_NOT_EXIST = [PG::Error, /cursor.*does not exist/]

    let(:select_statement) do
      sql = Select.new
      sql.select('i')
      sql.from('table1')
      sql
    end

    let(:hold) {nil}
    let(:scroll) {nil}

    def make_cursor
      cursor = Cursor.new('cursor1',
                          select_statement,
                          {
                            :hold => hold,
                            :scroll => scroll,
                          },
                          connection)
    end

    def make_cursor_in_transaction
      cursor = nil
      Transaction.new(connection) do
        cursor = make_cursor
      end
      cursor
    end

    let(:cursor) {make_cursor}

    shared_context 'table for cursor test' do |table_name|

      include_context('temporary table',
                      :table_name => table_name,
                      :columns => ['i int'])

      before(:each) do
        5.times do |i|
          sql = Insert.new(table_name, connection)
          sql.insert('i', i)
          sql.exec
        end
      end

    end

    shared_context 'table1 for cursor test' do
      include_context 'table for cursor test', 'table1'
    end

    shared_context 'table2 for cursor test' do
      include_context 'table for cursor test', 'table2'
    end

    describe 'scroll' do
      
      include_context 'table1 for cursor test'
      include_context 'table2 for cursor test'

      let(:select_statement) do
        sql = Select.new
        sql.select('i')
        sql.from('table1')
        sql.join_using('inner', 'table2', 'i')
        sql.where('i % 2 = 0')
        sql
      end

      shared_examples_for 'is a scroll cursor' do
        test_connection do |test_connection|
          let(:connection) {test_connection}
          specify do
            Transaction.new(connection) do
              cursor.fetch.should == [{'i' => 0}]
              cursor.fetch.should == [{'i' => 2}]
              cursor.fetch('PRIOR').should == [{'i' => 0}]
              cursor.fetch('PRIOR').should == []
            end
          end
        end
      end

      shared_examples_for 'is a no scroll cursor' do
        test_connection do |test_context|
          let(:connection) {test_connection}
          specify do
            Transaction.new(connection) do
              expect {
                cursor.fetch('PRIOR')
              }.to raise_error PG::Error, /cursor can only scan forward/
            end
          end
        end
      end

      context '(on)' do
        let(:scroll) {true}
        it_behaves_like 'is a scroll cursor'
      end

      context '(off)' do
        let(:scroll) {false}
        it_behaves_like 'is a no scroll cursor'
      end

      context '(default)' do
        let(:scroll) {nil}
        it_behaves_like 'is a no scroll cursor'
      end

    end

    describe 'hold' do
      
      include_context 'table1 for cursor test'

      let(:cursor) {make_cursor_in_transaction}

      shared_examples 'cursor persists after transaction' do
        test_connection do |test_context|
          let(:connection) {test_connection}
          specify do
            cursor = make_cursor_in_transaction
            cursor.fetch.should == [{'i' => 0}]
            cursor.close
          end
        end
      end

      shared_examples_for 'cursor closed when transaction ends' do
        test_connection do |test_context|
          let(:connection) {test_connection}
          specify do
            cursor = make_cursor_in_transaction
            expect {
              cursor.fetch
            }.to raise_error *CURSOR_DOES_NOT_EXIST
          end
        end
      end

      context '(on)' do
        let(:hold) {true}
        it_behaves_like 'cursor persists after transaction'
      end

      context '(off)' do
        let(:hold) {false}
        it_behaves_like 'cursor closed when transaction ends'
      end

      context '(default)' do
        let(:hold) {nil}
        it_behaves_like 'cursor closed when transaction ends'
      end

    end

    describe '#initialize' do

      context '(taking block)' do

        test_connection do |test_context|
          let(:connection) {test_connection}

          include_context 'table1 for cursor test', test_connection

          specify do
            Transaction.new(connection) do
              Cursor.new('cursor1',
                         select_statement,
                         {},
                         connection) do |cursor|
                cursor.fetch.should == [{'i' => 0}]
              end
            end
            
          end

        end

      end

    end

    describe '#close' do

      include_context 'table1 for cursor test'

      test_connections.each do |test_context, test_connection|
        context test_context do
          let(:connection) {test_connection}

          it 'cannot be used after being closed' do
            Transaction.new(connection) do
              cursor = make_cursor
              cursor.close
              expect {
                cursor.fetch
              }.to raise_error *CURSOR_DOES_NOT_EXIST
            end
          end

        end
      end


    end

    describe '#move' do

      test_connections.each do |test_context, test_connection|
        context test_context do
          let(:connection) {test_connection}

          include_context 'table1 for cursor test', test_connection

          specify do
            Transaction.new(connection) do
              cursor = make_cursor
              cursor.move('absolute 2')
              cursor.fetch.should == [{'i' => 2}]
            end
          end

        end
      end

    end

    describe '#fetch' do

      context '(default)' do

        test_connection do |test_context|
          let(:connection) {test_connection}

          include_context 'table1 for cursor test', test_connection

          specify do
            Transaction.new(connection) do
              cursor.fetch.should == [{'i' => 0}]
              cursor.fetch.should == [{'i' => 1}]
              cursor.fetch.should == [{'i' => 2}]
              cursor.fetch.should == [{'i' => 3}]
              cursor.fetch.should == [{'i' => 4}]
              cursor.fetch.should == []
            end
          end

        end

      end

      context '(with count)' do

        test_connection do |test_context|
          let(:connection) {test_connection}

          include_context 'table1 for cursor test', test_connection

          specify do
            Transaction.new(connection) do
              cursor = Cursor.new('cursor1', select_statement, {}, connection)
              cursor.fetch(2).should == [{'i' => 0}, {'i' => 1}]
              cursor.fetch(2).should == [{'i' => 2}, {'i' => 3}]
              cursor.fetch(2).should == [{'i' => 4}]
              cursor.fetch.should == []
            end
          end

        end

      end

    end

  end

end
