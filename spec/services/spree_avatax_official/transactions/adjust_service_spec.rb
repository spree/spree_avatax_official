require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::AdjustService, :avalara_integration do
  describe '#call' do
    context 'with correct parameters' do
      subject do
        described_class.call(
          order:             order.reload,
          adjustment_reason: 'PriceAdjusted'
        )
      end

      # Bump number when re-recording — AvaTax rejects re-committing the same code.
      let(:order) { create(:completed_order_with_totals, number: 'R777111000', line_items_count: 1, ship_address: create(:usa_address)) }

      it 'returns positive result' do
        avalara_integration.update!(active: false)
        order
        avalara_integration.update!(active: true)

        VCR.use_cassette('spree_avatax_official/transactions/adjust/invoice_order_success') do
          SpreeAvataxOfficial::Transactions::CreateService.call(order: order)

          result   = subject
          response = result.value

          expect(result.success?).to eq true
          expect(response['type']).to eq 'SalesInvoice'
          expect(response['status']).to eq 'Committed'
          expect(response['lines'].size).to eq 2
          expect(SpreeAvataxOfficial::Transaction.count).to eq 1
        end
      end
    end

    context 'with incorrect parameters' do
      subject do
        described_class.call(
          order:             order.reload,
          adjustment_reason: ''
        )
      end

      # Bump number when re-recording.
      let(:order) { create(:completed_order_with_totals, number: 'R777111001', ship_address: create(:usa_address)) }

      it 'returns negative result' do
        avalara_integration.update!(active: false)
        order
        avalara_integration.update!(active: true)

        VCR.use_cassette('spree_avatax_official/transactions/adjust/failure') do
          SpreeAvataxOfficial::Transactions::CreateService.call(order: order)

          result   = subject
          response = result.value

          expect(result.success?).to eq false
          expect(response['error']).to be_present
          expect(response['error']['code']).to eq 'ModelStateInvalid'
        end
      end
    end
  end
end
