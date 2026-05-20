require 'spec_helper'

describe SpreeAvataxOfficial::GetTaxService, :avalara_integration do
  subject { described_class.call(order: order) }

  describe '#call' do
    let(:order) { create(:avatax_order, line_items_count: 1, ship_address: create(:usa_address)) }

    context 'with successed response from avatax' do
      it 'returns success with tax calculated' do
        avalara_integration.update!(active: false)
        order
        avalara_integration.update!(active: true)

        VCR.use_cassette('spree_avatax_official/get_tax/sucsess') do
          result = subject

          expect(result.success?).to eq true
          expect(result.value[:taxCalculated]).to eq 0.8
        end
      end
    end

    context 'with errors returned from avatax' do
      let(:order) { create(:order, ship_address: create(:usa_address)) }

      it 'returns failure with errors' do
        avalara_integration.update!(active: false)
        order
        avalara_integration.update!(active: true)

        VCR.use_cassette('spree_avatax_official/get_tax/error') do
          result = subject

          expect(result.failure?).to eq true
          expect(result.value.body['error']).to be_present
        end
      end
    end
  end
end
