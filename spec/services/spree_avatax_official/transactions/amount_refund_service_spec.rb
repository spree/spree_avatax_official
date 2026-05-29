require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::AmountRefundService, :avalara_integration do
  describe '#call' do
    subject { described_class.call(order: order, transaction_code: "#{order.number}-1", amount: amount) }

    let(:order)  { create(:shipped_order, line_items_count: 2, ship_address: create(:usa_address), number: 'R100000011') }
    let(:amount) { (order.total / 5).round(2) }

    before do
      avalara_integration.update!(active: false)
      order.update(completed_at: Time.current)
      order.update_with_updater!
      avalara_integration.update!(active: true)
    end

    it 'creates a ReturnInvoice via the RefundTransaction endpoint' do
      VCR.use_cassette('spree_avatax_official/transactions/refund/amount_refund_success') do
        sales_invoice = SpreeAvataxOfficial::Transactions::CreateService.call(order: order)
        invoice_tax   = sales_invoice.value['totalTax']

        # Reflect the committed SalesInvoice's tax on the Spree order so order.total matches what the customer paid:
        # item_total ($20) + ship_total ($10) + tax ($2.40) = $32.40.
        order.update_columns(
          additional_tax_total: invoice_tax,
          total:                order.item_total + order.shipment_total + invoice_tax
        )

        expect(order.total).to eq 32.40
        expect(amount).to eq 6.48

        result   = subject
        response = result.value

        expect(result.success?).to eq true
        expect(response['type']).to eq 'ReturnInvoice'
        expect(response['status']).to eq 'Committed'
        expect(response['code']).to eq "#{order.number}-1"
        expect(response['referenceCode']).to eq order.number

        # Amount is 20% of order.total, so refundPercentage is 20. The customer-facing refund
        # (taxable amount + tax) equals the amount Spree asked to refund.
        expect(-(response['totalAmount'] + response['totalTax'])).to eq amount.to_f
        expect(response['totalAmount']).to eq(-((order.item_total + order.shipment_total) * 0.2).round(2))
        expect(response['totalTax']).to eq(-(invoice_tax * 0.2).round(2))

        tax_codes = response['lines'].map { |line| line['taxCode'] }
        expect(tax_codes).to contain_exactly('P0000000', 'P0000000', 'FR')

        expect(SpreeAvataxOfficial::Transaction.count).to eq 2
        expect(SpreeAvataxOfficial::Transaction.last.transaction_type).to eq 'ReturnInvoice'
      end
    end
  end
end
