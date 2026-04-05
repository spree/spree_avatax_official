require 'spec_helper'

describe SpreeAvataxOfficial::Address::Validate, :avalara_integration do
  describe '#call' do
    let(:order) { create(:order) }

    subject { described_class.call(address: address, order: order) }

    context 'with valid address' do
      let(:address) { create(:usa_address) }

      it 'returns success' do
        VCR.use_cassette('spree_avatax_official/address/validate_success') do
          response = subject

          expect(response.success?).to eq true
        end
      end
    end

    context 'with invalid address' do
      let(:address) { create(:invalid_usa_address) }

      it 'returns failure with messages' do
        VCR.use_cassette('spree_avatax_official/address/validate_failure') do
          response = subject

          expect(response.failure?).to eq true
          expect(response.value.body['messages']).to be_present
        end
      end

      context 'with too long zipcode' do
        let(:address) { create(:usa_address) }

        it 'returns failure with messages' do
          address.update_column(:zipcode, 'too_long_zipcode')

          VCR.use_cassette('spree_avatax_official/address/zipcode_failure') do
            response = subject

            expect(response.failure?).to eq true
            expect(response.value.body['error']['message']).to be_present
          end
        end
      end
    end
  end
end
