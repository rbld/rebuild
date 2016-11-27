require_relative '../../cli/lib/rbld_registry'

module Rebuild
  module Utils

    describe Error do
      context 'when prefix is given' do
        it 'joins message with prefix' do
          expect { raise Error.new( 'pfx', nil, 'msg' ) }.to raise_error('pfx: msg')
        end

        it 'uses prefix as message when no message is given' do
          expect { raise Error.new( 'pfx', nil, nil ) }.to raise_error('pfx')
        end
      end

      context 'when format sequence is given' do
        it 'formats message accordingly' do
          expect { raise Error.new( nil, 'test %s', 'msg' ) }.to raise_error('test msg')
        end
      end

      context 'only message is given' do
        it 'leaves messsage as is ' do
          expect { raise Error.new( nil, nil, 'msg' ) }.to raise_error('msg')
        end
      end
    end

  end
end
