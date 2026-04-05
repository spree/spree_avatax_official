require 'spec_helper'

describe SpreeAvataxOfficial::GenerateTransactionCacheKeyService, :avalara_integration do
  subject { described_class.call(order: order) }

  describe '#call' do
    context 'when order is before completion' do
      let(:order) { create(:avatax_order, ship_address: create(:usa_address)) }

      it 'returns compressed cache key' do
        result = subject

        expect(result.success?).to eq true
        expect(result.value).to include('AvaTax-transaction')
      end
    end

    context 'when order is completed' do
      let(:order) { create(:avatax_order, :completed, line_items_count: 1, with_shipment: true, ship_address: create(:usa_address)) }

      it 'returns compressed cache key' do
        result = subject

        expect(result.success?).to eq true
        expect(result.value).to include('AvaTax-transaction')
      end
    end
  end
end
