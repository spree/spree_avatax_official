require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::PartialRefundService, :avalara_integration do
  describe '#call' do
    subject do
      described_class.call(
        order:            order,
        transaction_code: 'test-code-1234',
        refund_items:     refund_item
      )
    end

    let(:order)       { create(:order_with_line_items, ship_address: create(:usa_address)) }
    let(:refund_item) { { line_item => [line_item.quantity - 1, -1 * line_item.amount] } }
    let(:line_item)   { order.line_items.first }

    it 'creates ReturnInvoice' do
      avalara_integration.update!(active: false)
      order.update(state: :complete, completed_at: Time.current)
      avalara_integration.update!(active: true)

      VCR.use_cassette('spree_avatax_official/transactions/refund/partial_refund_success') do
        result   = subject
        response = result.value

        expect(result.success?).to eq true
        expect(response['type']).to eq 'ReturnInvoice'
        expect(response['status']).to eq 'Committed'
        expect(response['lines'].size).to eq 1
        expect(response['lines'].first['lineAmount']).to eq(-10)
        expect(SpreeAvataxOfficial::Transaction.count).to eq 1
      end
    end
  end
end
