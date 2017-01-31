require_relative '../../cli/lib/rbld_config'

module Rebuild
  describe Remote do
    before :each do
      @cfg = { 'REMOTE_NAME' => 'origin',
               'REMOTE_TYPE_origin' => 'rebuild',
               'REMOTE_origin' => 'origin_path' }
      @remote = Remote.new(@cfg)
    end

    it 'knows its name' do
      expect(@remote.name).to be == 'origin'
    end

    it 'knows its type' do
      expect(@remote.type).to be == 'rebuild'
    end

    it 'knows its path' do
      expect(@remote.path).to be == 'origin_path'
    end

    it 'is valid when all fields are specified' do
      expect{ @remote.validate! }.not_to raise_error
    end

    it 'is invalid without name' do
      @cfg['REMOTE_NAME'] = nil
      @remote = Remote.new(@cfg)
      expect{ @remote.validate! }.to raise_error('Remote not defined')
    end

    it 'is invalid without type' do
      @cfg['REMOTE_TYPE_origin'] = nil
      @remote = Remote.new(@cfg)
      expect{ @remote.validate! }.to raise_error('Remote type not defined')
    end

    it 'is invalid without path' do
      @cfg['REMOTE_origin'] = nil
      @remote = Remote.new(@cfg)
      expect{ @remote.validate! }.to raise_error('Remote location not defined')
    end

    ['docker', 'rebuild'].each do |t|
      it "is valid for remote of type #{t}" do
        @cfg['REMOTE_TYPE_origin'] = t
        @remote = Remote.new(@cfg)
        expect{ @remote.validate! }.not_to raise_error
      end
    end
  end

  describe 'Remote#validate!' do
    it 'returns self when valid' do
      @cfg = { 'REMOTE_NAME' => 'origin',
               'REMOTE_TYPE_origin' => 'rebuild',
               'REMOTE_origin' => 'origin_path' }
      @remote = Remote.new(@cfg)
      expect(@remote.validate!).to be_equal @remote
    end

    it 'raises an error when invalid' do
      @remote = Remote.new(nil)
      expect{ @remote.validate! }.to raise_error(RuntimeError)
    end
  end
end
