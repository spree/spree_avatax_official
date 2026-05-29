require 'spec_helper'

RSpec.describe Spree::Integrations::Avalara do
  describe 'validations' do
    it 'requires preferred_account_number' do
      integration = build(:avalara_integration, preferred_account_number: nil)
      expect(integration).not_to be_valid
      expect(integration.errors[:preferred_account_number]).to include(/can't be blank/)
    end

    it 'requires preferred_license_key' do
      integration = build(:avalara_integration, preferred_license_key: nil)
      expect(integration).not_to be_valid
      expect(integration.errors[:preferred_license_key]).to include(/can't be blank/)
    end

    it 'requires preferred_company_code' do
      integration = build(:avalara_integration, preferred_company_code: nil)
      expect(integration).not_to be_valid
      expect(integration.errors[:preferred_company_code]).to include(/can't be blank/)
    end
  end

  describe '#can_connect?' do
    subject(:integration) { build(:avalara_integration) }

    context 'with valid sandbox credentials', vcr: { cassette_name: 'spree/integrations/avalara/can_connect/authenticated' } do
      it 'returns true and leaves connection_error_message blank' do
        expect(integration.can_connect?).to eq(true)
        expect(integration.connection_error_message).to be_nil
      end
    end

    context 'with invalid credentials', vcr: { cassette_name: 'spree/integrations/avalara/can_connect/unauthenticated' } do
      subject(:integration) do
        build(:avalara_integration,
              preferred_account_number: '0000000000',
              preferred_license_key:    'invalid_license_key')
      end

      it 'returns false and reports invalid credentials' do
        expect(integration.can_connect?).to eq(false)
        expect(integration.connection_error_message).to eq('Invalid credentials')
      end
    end


    context 'when the AvaTax host is unreachable' do
      before do
        stub_request(:get, %r{sandbox-rest\.avatax\.com/api/v2/utilities/ping})
          .to_raise(Faraday::ConnectionFailed.new('connection refused'))
      end

      it 'returns false and surfaces the underlying error message' do
        expect(integration.can_connect?).to eq(false)
        expect(integration.connection_error_message).to include('connection refused')
      end
    end

    context 'when AvaTax returns an unexpected non-JSON body' do
      before do
        stub_request(:get, %r{sandbox-rest\.avatax\.com/api/v2/utilities/ping}).to_return(
          status: 502,
          headers: { 'Content-Type' => 'text/html' },
          body: '<html>Bad Gateway</html>'
        )
      end

      it 'returns false and falls back to the generic message' do
        expect(integration.can_connect?).to eq(false)
        expect(integration.connection_error_message).to eq('Could not connect to AvaTax')
      end
    end
  end
end
