require_relative '../../cli/lib/rbld_commands'
require_relative 'rbld_utils_shared'

module Rebuild
  module CLI

    [EnvironmentNameEmpty,
     EnvironmentNameWithoutTagExpected,
     EnvironmentNameError,
     HandlerClassNameError].each do |c|
       describe c do
         include_examples 'rebuild error class'
       end
     end

    describe Environment do
      shared_examples 'it fetches its name' do
        it 'and stores it' do
          expect(obj.name).to be == 'env'
        end
      end
      shared_examples 'it fetches its tag' do
        it 'and stores it' do
          expect(obj.tag).to be == 'v001'
        end
      end

      context 'when both name and tag are used' do
        let(:obj) { Environment.new('env:v001') }

        it_behaves_like 'it fetches its name'
        it_behaves_like 'it fetches its tag'

        it 'knows its full name' do
          expect(obj.full).to be == 'env:v001'
        end

        it 'supports string representation as full name' do
          expect(obj.to_s).to be == obj.full
        end
      end

      context 'when only name is used' do
        let(:obj) { Environment.new('env') }

        it_behaves_like 'it fetches its name'

        it 'uses default tag' do
          expect(obj.tag).to be == 'initial'
        end
      end

      context 'when no tag is forced' do
        context 'when no tag is given' do
          let(:obj) { Environment.new('env', force_no_tag: true) }

          it_behaves_like 'it fetches its name'

          it 'assumes default tag' do
            expect(obj.tag).to be == 'initial'
          end
        end

        it 'raises when tag is given' do
          expect { Environment.new('env:tag', force_no_tag: true) }.to \
            raise_error('Environment tag must not be specified')
        end
      end

      context 'when empty name is allowed' do
        it 'fetches empty name and tag when nil is given' do
          obj = Environment.new(nil, allow_empty: true)
          expect([obj.name, obj.tag]).to be == ['', '']
        end

        it 'fetches empty name and tag when empty string is given' do
          obj = Environment.new('', allow_empty: true)
          expect([obj.name, obj.tag]).to be == ['', '']
        end

        context 'when only name is given' do
          let(:obj) { Environment.new('env', allow_empty: true) }
          it 'fetches given name' do
            expect(obj.name).to be == 'env'
          end
          it 'fetches empty tag' do
            expect(obj.tag).to be_empty
          end
        end

        context 'when only tag is given' do
          let(:obj) { Environment.new(':tag', allow_empty: true) }

          it 'fetches empty name and tag' do
            expect([obj.name, obj.tag]).to be == ['', '']
          end
        end
      end

      context 'when parsed name is given' do
        let(:obj) { Environment.new(OpenStruct.new(name: 'env', tag: 'v001')) }
        it_behaves_like 'it fetches its name'
        it_behaves_like 'it fetches its tag'
      end

      context 'on construction' do
        it 'raises on no input' do
          expect{Environment.new(nil)}.to \
            raise_error('Environment name not specified')
        end

        it 'validates given name' do
          expect{Environment.new('invalid~name:v001')}.to \
            raise_error('Invalid environment name (invalid~name), ' \
                        'it may contain lowercase and uppercase letters, digits, underscores, periods and dashes and may not start or end with a dash, period or underscore.')
        end
        it 'validates given tag' do
          expect{Environment.new('env:invalid~tag')}.to \
            raise_error('Invalid environment tag (invalid~tag), ' \
                        'it may contain lowercase and uppercase letters, digits, underscores, periods and dashes and may not start with a period or a dash.')
        end
      end

      context 'validates given environment name component' do
        it 'raises error on validation failure' do
          expect{ Environment.validate_tag_name('new tag', 'invalid~tag') }.to \
            raise_error('Invalid new tag (invalid~tag), ' \
                        'it may contain lowercase and uppercase letters, digits, underscores, periods and dashes and may not start with a period or a dash.')
        end

        it 'does not raise any error on validation success' do
          expect{ Environment.validate_environment_name('new tag', 'valid-tag') }.to_not \
            raise_error
        end
      end
    end

    describe Commands do
      let(:tracker) { instance_double('Command') }

      before :all do
        class RbldTest1Command < Command
          class << self; attr_accessor :tracker; end
          def run(params); self.class.tracker.run(params); end
          def usage; self.class.tracker.usage; end
        end
        class RbldTest2Command < Command; end
      end

      it 'tracks classes derived from Command' do
        expect(Commands.count).to be == 2
      end

      it 'provides means to enumerate registered commands' do
        expect { |b| Commands.each(&b) }.to \
          yield_successive_args('test1', 'test2')
      end

      it 'raises an error when class derived from Command does not follow naming convention' do
        expect { class NonParsableName < Command; end }.to \
          raise_error(HandlerClassNameError, 'Rebuild::CLI::NonParsableName')
      end

      it 'knows how to run a command' do
        RbldTest1Command.tracker = tracker
        expect(tracker).to receive(:run).with('arg')
        Commands.run('test1', 'arg')
      end

      it 'knows how to request a command usage' do
        RbldTest1Command.tracker = tracker
        expect(tracker).to receive(:usage).with(no_args)
        Commands.usage('test1')
      end

      it 'returns command usage text when requested' do
        RbldTest1Command.tracker = tracker
        allow(tracker).to receive(:usage).and_return('usage text')
        expect(Commands.usage('test1')).to be == 'usage text'
      end
    end

  end
end
