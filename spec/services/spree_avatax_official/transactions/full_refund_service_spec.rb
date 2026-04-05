require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::FullRefundService, :avalara_integration do
  describe '#call' do
    subject { described_class.call(order: order, transaction_code: 'REFUND7482-1') }

    let(:order)         { create(:completed_order_with_totals, ship_address: create(:usa_address), number: 'REFUND7482') }
    let(:refundable_id) { 1 }

    it 'creates refund transaction' do
      VCR.use_cassette('spree_avatax_official/transactions/refund/full_refund_success') do
        SpreeAvataxOfficial::Transactions::CreateService.call(order: order)

        result   = subject
        response = result.value

        expect(result.success?).to eq true
        expect(response['type']).to eq 'ReturnInvoice'
        expect(SpreeAvataxOfficial::Transaction.count).to eq 2
        expect(SpreeAvataxOfficial::Transaction.last.transaction_type).to eq 'ReturnInvoice'
      end
    end
  end
end
