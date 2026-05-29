require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::VoidService, :avalara_integration do
  let(:order) { create(:completed_order_with_totals, number: 'R555111223', ship_address: create(:usa_address)) }

  describe '#call' do
    subject { described_class.call(order: order.reload) }

    context 'with correct parameters' do
      it 'returns positive result' do
        # Suppress factory chain HTTP — we want exactly two requests
        # captured: the explicit CreateService and the subject (Void).
        avalara_integration.update!(active: false)
        order
        avalara_integration.update!(active: true)

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
      # VoidService short-circuits when the order has no local SalesInvoice
      # row. No HTTP needed — keep the integration inactive so the factory
      # chain doesn't fire `update_tax_charge` callbacks.
      before { avalara_integration.update!(active: false) }

      it 'returns negative result' do
        result   = subject
        response = result.value

        expect(result.success?).to eq false
        expect(response).to eq 'Order is missing SalesInvoice transaction'
      end
    end
  end
end
