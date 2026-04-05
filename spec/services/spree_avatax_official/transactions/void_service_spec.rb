require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::VoidService, :avalara_integration do
  let(:order) { create(:completed_order_with_totals, number: 'R251928987', ship_address: create(:usa_address)) }

  describe '#call' do
    subject { described_class.call(order: order.reload) }

    context 'with correct parameters' do
      it 'returns positive result' do
        VCR.use_cassette('spree_avatax_official/transactions/void/success') do
          SpreeAvataxOfficial::Transactions::CreateService.call(order: order)

          result   = subject
          response = result.value

          expect(result.success?).to eq true
          expect(response['status']).to eq 'Cancelled'
        end
      end
    end

    context 'when order does NOT have SalesInvoice transaction' do
      it 'returns negative result' do
        result   = subject
        response = result.value

        expect(result.success?).to eq false
        expect(response).to eq 'Order is missing SalesInvoice transaction'
      end
    end
  end
end
