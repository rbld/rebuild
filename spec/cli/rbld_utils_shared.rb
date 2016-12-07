shared_examples 'rebuild error class' do |prefix = nil|
  it 'derives from Rebuild::Utils::Error' do
    expect(described_class).to be < Rebuild::Utils::Error
  end
  it 'was defined by rebuild_error(s) function' do
    expect(described_class.send(:defined_by_rebuild_error_helper)).to be true
  end
end
