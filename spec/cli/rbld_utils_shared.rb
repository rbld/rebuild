shared_examples 'it derives from Rebuild::Utils::Error' do
  it 'derives from Rebuild::Utils::Error' do
    expect(described_class).to be < Rebuild::Utils::Error
  end
end

shared_examples 'it supports customized prefix' do |prefix = nil|
  it 'joins given message with customized prefix' do
    message = prefix.to_s.empty? ? 'msg' : "#{prefix}: msg"
    expect { raise described_class, 'msg' }.to raise_error(message)
  end
end

shared_examples 'rebuild error class' do |prefix = nil|
  it_behaves_like 'it derives from Rebuild::Utils::Error'
  it_behaves_like 'it supports customized prefix', prefix
end
