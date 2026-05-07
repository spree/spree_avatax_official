require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::FullRefundService, :avalara_integration do
  describe '#call' do
    # `number:` and `transaction_code:` are baked into the cassette URLs
    # (FullRefundService POSTs to `/transactions/<number>/refund`). Bump these
    # when re-recording — AvaTax rejects re-committing the same code.
    subject { described_class.call(order: order, transaction_code: 'R987654321-1') }

    let(:order)         { create(:completed_order_with_totals, ship_address: create(:usa_address), number: 'R987654321') }
    let(:refundable_id) { 1 }

    it 'creates refund transaction' do
      # Suppress factory chain's tax-recalc HTTP — the test wants exactly two
      # HTTP calls captured: the explicit CreateService (SalesInvoice) and
      # the subject (ReturnInvoice).
      avalara_integration.update!(active: false)
      order
      avalara_integration.update!(active: true)

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
