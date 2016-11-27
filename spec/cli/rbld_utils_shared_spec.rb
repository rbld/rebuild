shared_examples 'it derives from Rebuild::Utils::Error' do
  it 'derives from Rebuild::Utils::Error' do
    expect(described_class).to be < Rebuild::Utils::Error
  end
end
