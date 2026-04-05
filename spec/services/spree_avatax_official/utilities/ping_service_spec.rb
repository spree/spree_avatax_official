require 'spec_helper'

describe SpreeAvataxOfficial::Utilities::PingService, :avalara_integration do
  subject { described_class.call(store: store) }

  let(:store) { Spree::Store.default }

  context 'with proper credentials' do
    it 'respond with success' do
      VCR.use_cassette('spree_avatax_official/utilities/ping') do
        expect(subject.success?).to eq true
        expect(subject['value']['authenticated']).to eq true
      end
    end
  end

  context 'unauthenticated' do
    it 'respond with success' do
      VCR.use_cassette('spree_avatax_official/utilities/ping_unauthorized') do
        expect(subject.success?).to eq true
        expect(subject['value']['authenticated']).to eq false
      end
    end
  end

  context 'timeout' do
    let(:connection_options) { { request: { timeout: 6, open_timeout: 0 } } }
    before do
      allow_any_instance_of(AvaTax::Client).to receive(:connection_options).and_return(connection_options) # rubocop:disable RSpec/AnyInstance
    end
    it 'respond with failure' do
      VCR.use_cassette('spree_avatax_official/utilities/timeout') do
        expect(subject.success?).to eq false
      end
    end
  end
end
