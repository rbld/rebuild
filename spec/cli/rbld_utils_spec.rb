require 'timecop'
require_relative '../../cli/lib/rbld_utils'

module Rebuild
  module Utils

    describe Error do
      context 'when format sequence is given' do
        it 'formats message accordingly' do
          expect { raise Error.new( 'test %s', 'msg' ) }.to raise_error('test msg')
        end
      end

      context 'only message is given' do
        it 'leaves messsage as is ' do
          expect { raise Error.new( nil, 'msg' ) }.to raise_error('msg')
        end
      end
    end

    describe FullImageName do
      let(:obj) { FullImageName.new('repo', 'tag') }

      it 'should know its repo' do
        expect(obj.repo).to be == 'repo'
      end

      it 'also returns repo when asked for name' do
        expect(obj.name).to be == obj.repo
      end

      it 'should know its tag' do
        expect(obj.tag).to be == 'tag'
      end

      it 'should build full name from repo and tag' do
        expect(obj.full).to be == 'repo:tag'
      end

      it 'should provide full name as object string representation' do
        expect(obj.to_s).to be == 'repo:tag'
      end
    end

    describe EnvNameHolder do
      let(:obj) { EnvNameHolder.new('n', 't') }

      it 'should know its name' do
        expect(obj.name).to be == 'n'
      end

      it 'should know its tag' do
        expect(obj.tag).to be == 't'
      end

      it 'should build full name from name and tag' do
        expect(obj.full).to be == 'n:t'
      end

      it 'should provide full name as object string representation' do
        expect(obj.to_s).to be == 'n:t'
      end
    end

    module Errors
        describe '#rebuild_error' do
          rebuild_error = Rebuild::Utils::Errors.instance_method(:rebuild_error)
          rebuild_errors = Rebuild::Utils::Errors.instance_method(:rebuild_errors)

          it 'is an alias for rebuild_errors' do
            expect(rebuild_error).to be == rebuild_errors
          end
        end
        describe '#rebuild_errors' do
          before :each do
            @TestModule = Module.new
          end

          context do
            before :each do
              @TestModule.class_eval { extend Rebuild::Utils::Errors
                                       rebuild_errors NewErrorClass: "Msg" }
            end

            it 'defines a class' do
              expect(@TestModule::NewErrorClass).to be_a(Class)
            end
            it 'defines a class derived from Rebuild::Utils::Error' do
              expect(@TestModule::NewErrorClass).to be < Rebuild::Utils::Error
            end
            it 'defines a class that knows how it was defined' do
              expect(@TestModule::NewErrorClass.send(:defined_by_rebuild_error_helper)).to be true
            end
          end
          context do
            before :each do
              @TestModule.class_eval { extend Rebuild::Utils::Errors
                                       rebuild_errors NewErrorClass1: "Msg1",
                                                      NewErrorClass2: "Msg2" }
            end

            it 'may define a few classes at once' do
              expect(@TestModule::NewErrorClass1).to be_a(Class)
              expect(@TestModule::NewErrorClass2).to be_a(Class)
            end
          end
          context do
            before :each do
              @TestModule.class_eval { extend Rebuild::Utils::Errors
                                       rebuild_errors NewErrorClass: "P1 %s P2 %d" }
            end

            it 'defines a class that knows how to format error messages with multiple parameters' do
              expect { raise @TestModule::NewErrorClass, ['one', 2] }.to \
                raise_error('P1 one P2 2')
            end
          end
          context do
            before :each do
              @TestModule.class_eval { extend Rebuild::Utils::Errors
                                       rebuild_errors NewErrorClass: "P1 %s" }
            end

            it 'defines a class that knows how to format error messages with one parameter' do
              expect { raise @TestModule::NewErrorClass, 'one' }.to \
                raise_error('P1 one')
            end
          end
          context do
            before :each do
              @TestModule.class_eval { extend Rebuild::Utils::Errors
                                       rebuild_errors NewErrorClass: "P1" }
            end

            it 'defines a class that knows how to format error messages without parameters' do
              expect { raise @TestModule::NewErrorClass }.to \
                raise_error('P1')
            end
          end
          context do
            before :each do
              @TestModule.class_eval { extend Rebuild::Utils::Errors
                                       rebuild_errors NewErrorClass: nil }
            end

            it 'defines a class that knows how to treat error messages without format' do
              expect { raise @TestModule::NewErrorClass, 'raw msg' }.to \
                raise_error('raw msg')
            end
          end
        end
    end

    describe StopWatch do

      before(:each) do
        Timecop.freeze
        @timer = subject
      end

      after(:each) { Timecop.return }

      describe '#time_ms' do
        it 'returns integer number of milliseconds' do
          expect(@timer.time_ms).to be_a_kind_of(Integer)
        end

        it 'tracks elapsed time' do
          Timecop.freeze(1)
          expect(@timer.time_ms).to be == 1000
        end
      end

      describe '#restart' do
        it 'resets elapsed time counter' do
          Timecop.freeze(1)
          @timer.restart
          expect(@timer.time_ms).to be == 0
        end
      end

    end

    describe WithProgressBar do
      let(:pbar) { class_double(ProgressBar) }
      let(:pbar_obj) { double }

      let(:target) do
        expect(target = double).to receive(:dummy)
        target
      end

      let(:tty) do
        d = instance_double(STDOUT.class)
        allow(d).to receive(:tty?).and_return(true)
        d
      end

      let(:nontty) do
        d = instance_double(STDOUT.class)
        allow(d).to receive(:tty?).and_return(false)
        d
      end

      it 'delegates all messages to target object' do
        WithProgressBar.new(target, [], pbar, nontty).dummy('param')
      end

      it 'does not create progress bar for non-tty console' do
        WithProgressBar.new(target, [], pbar, nontty).dummy
      end

      it 'creates progress bar for tty console' do
        expect(pbar_obj).to receive(:increment)
        expect(pbar).to receive(:create).and_return(pbar_obj)
        WithProgressBar.new(target, :dummy, pbar, tty).dummy
      end

      it 'does not advance progress bar by default' do
        expect(pbar).to receive(:create).and_return(pbar_obj)
        WithProgressBar.new(target, [], pbar, tty).dummy
      end

      it 'advances progress bar for a given method' do
        expect(pbar).to receive(:create).and_return(pbar_obj)
        expect(pbar_obj).to receive(:increment)
        WithProgressBar.new(target, :dummy, pbar, tty).dummy
      end

      it 'advances progress bar for a given set of methods' do
        expect(pbar).to receive(:create).and_return(pbar_obj)
        expect(pbar_obj).to receive(:increment).twice
        expect(target).to receive(:foo)
        Timecop.freeze do
          obj = WithProgressBar.new(target, [:dummy, :foo], pbar, tty)
          obj.dummy
          Timecop.freeze(1)
          obj.foo
        end
      end

      it 'does not advance progress bar too fast' do
        expect(pbar).to receive(:create).and_return(pbar_obj)
        expect(pbar_obj).to receive(:increment).once
        allow(target).to receive(:dummy).twice
        Timecop.freeze do
          obj = WithProgressBar.new(target, :dummy, pbar, tty)
          obj.dummy
          obj.dummy
        end
      end

    end
  end
end
