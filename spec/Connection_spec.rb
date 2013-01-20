require File.expand_path('spec_helper', File.dirname(__FILE__))

module SqlPostgres

  describe Connection do

    let(:pg_connection) {mock PG}

    describe 'host_name' do

      before(:each) do
        PG.should_receive(:connect)\
          .with(expected_host_name,
                anything,
                anything,
                anything,
                anything,
                anything,
                anything)\
          .and_return(pg_connection)
      end

      def make_connection
        Connection.new('host_name' => host_name)
      end

      context '(default)' do
        let(:host_name) {nil}
        let(:expected_host_name) {'localhost'}
        specify {make_connection}
      end

      context '(supplied)' do
        let(:host_name) {'somehost'}
        let(:expected_host_name) {host_name}
        specify {make_connection}
      end

    end

    describe 'port' do

      before(:each) do
        PG.should_receive(:connect)\
          .with(anything,
                expected_port,
                anything,
                anything,
                anything,
                anything,
                anything)\
          .and_return(pg_connection)
      end

      def make_connection
        Connection.new('port' => port)
      end

      context '(default)' do
        let(:port) {nil}
        let(:expected_port) {5432}
        specify {make_connection}
      end

      context '(supplied)' do
        let(:port) {1234}
        let(:expected_port) {port}
        specify {make_connection}
      end

    end

    describe 'options' do

      before(:each) do
        PG.should_receive(:connect)\
          .with(anything,
                anything,
                expected_options,
                anything,
                anything,
                anything,
                anything)\
          .and_return(pg_connection)
      end

      def make_connection
        Connection.new('options' => options)
      end

      context '(default)' do
        let(:options) {nil}
        let(:expected_options) {''}
        specify {make_connection}
      end

      context '(supplied)' do
        let(:options) {'back end options'}
        let(:expected_options) {options}
        specify {make_connection}
      end

    end

    describe 'tty' do

      before(:each) do
        PG.should_receive(:connect)\
          .with(anything,
                anything,
                anything,
                expected_tty,
                anything,
                anything,
                anything)\
          .and_return(pg_connection)
      end

      def make_connection
        Connection.new('tty' => tty)
      end

      context '(default)' do
        let(:tty) {nil}
        let(:expected_tty) {''}
        specify {make_connection}
      end

      context '(supplied)' do
        let(:tty) {'tty name'}
        let(:expected_tty) {tty}
        specify {make_connection}
      end

    end

    describe 'db_name' do

      before(:each) do
        PG.should_receive(:connect)\
          .with(anything,
                anything,
                anything,
                anything,
                expected_db_name,
                anything,
                anything)\
          .and_return(pg_connection)
      end

      def make_connection
        Connection.new('db_name' => db_name)
      end

      context '(default)' do
        let(:db_name) {nil}
        let(:expected_db_name) {''}
        specify {make_connection}
      end

      context '(supplied)' do
        let(:db_name) {'somedatabase'}
        let(:expected_db_name) {db_name}
        specify {make_connection}
      end

    end

    describe 'login' do

      before(:each) do
        PG.should_receive(:connect)\
          .with(anything,
                anything,
                anything,
                anything,
                anything,
                expected_login,
                anything)\
          .and_return(pg_connection)
      end

      def make_connection
        Connection.new('login' => login)
      end

      context '(default)' do
        let(:login) {nil}
        let(:expected_login) {nil}
        specify {make_connection}
      end

      context '(supplied)' do
        let(:login) {'someuser'}
        let(:expected_login) {login}
        specify {make_connection}
      end

    end

    describe 'password' do

      before(:each) do
        PG.should_receive(:connect)\
          .with(anything,
                anything,
                anything,
                anything,
                anything,
                anything,
                expected_password)\
          .and_return(pg_connection)
      end

      def make_connection
        Connection.new('password' => password)
      end

      context '(default)' do
        let(:password) {nil}
        let(:expected_password) {nil}
        specify {make_connection}
      end

      context '(supplied)' do
        let(:password) {'somepassword'}
        let(:expected_password) {password}
        specify {make_connection}
      end

    end

    describe 'encoding' do

      before(:each) do
        PG.should_receive(:connect).and_return(pg_connection)
      end

      def make_connection
        Connection.new('encoding' => encoding)
      end

      context '(default)' do
        let(:encoding) {nil}
        specify {make_connection}
      end

      context '(supplied)' do
        let(:encoding) {'UNICODE'}
        before(:each) do
          pg_connection.should_receive(:set_client_encoding).with(encoding)
        end
        specify {make_connection}
      end

    end

    describe 'statement_in_exception' do

      before(:each) do
        PG.should_receive(:connect).and_return(pg_connection)
      end

      subject do
        Connection.new('statement_in_exception' => statement_in_exception)
      end

      context '(default)' do
        let(:statement_in_exception) {nil}
        its(:statement_in_exception) {should be_true}
      end

      context '(supplied)' do
        let(:statement_in_exception) {mock 'boolean'}
        its(:statement_in_exception) {should == statement_in_exception}
      end

    end

    describe '#pgconn' do

      context '(when wrapped)' do
        subject {Connection.new('connection' => pg_connection)}
        before(:each) do
          PG.should_not_receive(:connect)
        end
        its(:pgconn) {should == pg_connection}        
      end

      context '(when created)' do
        subject {Connection.new}
        before(:each) do
          PG.should_receive(:connect).and_return(pg_connection)
        end
        its(:pgconn) {should == pg_connection}        
      end

    end

    describe '#close' do

      subject(:connection) {Connection.new}

      before(:each) do
        PG.should_receive(:connect).and_return(pg_connection)
        pg_connection.should_receive(:close).once
      end

      specify do
        connection.close
        connection.close
      end

    end

    describe 'default connection' do

      context '(when not set)' do
        # Odd: "be_kind_of" doesn't work here.
        # Connection.default.should be_kind_of(NullConnection)
        Connection.default.class.should == NullConnection
      end

      context '(when set)' do
        let(:default_connection) {mock Connection}
        specify do
          Connection.default = default_connection
          Connection.default.should == default_connection
        end
      end

    end

    describe '.open' do

      let(:args) {mock 'arguments'}
      let(:connection) {mock Connection}

      before(:each) do
        Connection.should_receive(:new).with(args).and_return(connection)
      end

      shared_context 'normal close' do
        before(:each) do
          connection.should_receive(:close)
        end
      end

      shared_context 'failed close' do
        let(:close_exception) {StandardError.new('failed to close')}
        before(:each) do
          connection.should_receive(:close).and_raise(close_exception)
        end
      end

      context '(normal yield)' do

        context '(normal close)' do

          include_context 'normal close'

          let(:block_result) {mock 'block result'}
          
          specify do
            Connection.open(args) do |yielded_connection|
              yielded_connection.should eql connection
              block_result
            end.should == block_result
          end

        end

        context '(failed close)' do

          include_context 'failed close'

          specify do
            expect {
              Connection.open(args) do
              end
            }.to raise_error close_exception
          end

        end

      end

      context '(exception in block)' do

        let(:block_exception) {StandardError.new('failed in block')}

        context '(normal close)' do

          include_context 'normal close'

          specify do
            expect {
              Connection.open(args) do
                raise block_exception
              end
            }.to raise_error block_exception
          end

        end

        context '(failed close)' do

          include_context 'failed close'

          specify do
            expect {
              Connection.open(args) do
                raise block_exception
              end
            }.to raise_error block_exception
          end

        end

      end

    end

    describe '#exec' do

      let(:statement_in_exception) {false}
      let(:statement) {'statement'}

      before(:each) do
        PG.should_receive(:connect).with(any_args).and_return(pg_connection)
      end

      subject(:connection) do
        Connection.new('statement_in_exception' => statement_in_exception)
      end

      context '(normal)' do

        let(:pgresult) {mock PG::Result}

        before(:each) do
          pg_connection.should_receive(:exec)\
            .with(statement).and_return(pgresult)
        end

        specify do
          connection.exec(statement).should == pgresult
        end

      end

      context '(exception)' do

        let(:message) {"query failed\n"}
        let(:exception) {PGError.new(message)}

        before(:each) do
          pg_connection.should_receive(:exec)\
            .with(statement).and_raise(exception)
        end

        context '(statement_in_exception = false)' do
          let(:statement_in_exception) {false}
          specify do
            expect {
              connection.exec(statement)
            }.to raise_error exception
          end
        end

        context '(statement_in_exception = true)' do
          let(:statement_in_exception) {true}
          specify do
            expect {
              connection.exec(statement)
            }.to raise_error(PGError) { |e|
              e.message.should match message
              e.message.should match statement.inspect
            }
          end
        end

      end

    end

    describe '#query' do

      let(:statement) {'statement'}

      before(:each) do
        PG.should_receive(:connect).with(any_args).and_return(pg_connection)
      end

      subject(:connection) do
        Connection.new
      end

      let(:values) {mock 'values'}
      let(:pgresult) {mock PG::Result, :values => values}

      before(:each) do
        pg_connection.should_receive(:exec)\
          .with(statement).and_return(pgresult)
      end

      specify do
        connection.query(statement).should == values
      end

    end

  end

end
