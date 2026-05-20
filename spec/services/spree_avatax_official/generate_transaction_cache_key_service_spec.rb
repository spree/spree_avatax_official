require 'spec_helper'

describe SpreeAvataxOfficial::GenerateTransactionCacheKeyService, :avalara_integration do
  subject { described_class.call(order: order) }

  # The cache-key generator only hashes local order/preference data — it never
  # talks to AvaTax. Flipping the integration inactive keeps Spree's recalculate
  # callbacks (`avatax_enabled?`) from firing real HTTP requests during the
  # `:avatax_order` factory chain.
  before { avalara_integration.update!(active: false) }

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

    describe 'cache key sensitivity' do
      let(:order) { create(:avatax_order, line_items_count: 1, ship_address: create(:usa_address)) }

      # `order.avalara_integration` is scoped to `.active`, so we need the
      # integration active for the cache key to incorporate its preferences.
      # Force factory eval first (still inactive from the outer `before`),
      # then flip active right before the assertions.
      before do
        order
        avalara_integration.update!(active: true)
      end

      it 'changes when the integration is updated (e.g. ship-from address)' do
        original_key = described_class.call(order: order).value

        avalara_integration.update!(preferred_ship_from_address: { line1: '1 Different St' })

        expect(described_class.call(order: order).value).not_to eq original_key
      end

      it 'changes when the market tax_inclusive flag flips' do
        original_key = described_class.call(order: order).value

        enable_tax_inclusive_for_order(order)

        expect(described_class.call(order: order).value).not_to eq original_key
      end

      it 'differs across integrations (multi-store isolation)' do
        other_store       = create(:store, default_currency: 'USD', default_country_id: Spree::Country.find_by(iso: 'US')&.id)
        other_integration = create(:avalara_integration, store: other_store, active: false)
        other_order       = create(:avatax_order, store: other_store, line_items_count: 1, ship_address: create(:usa_address))
        other_integration.update!(active: true)

        expect(described_class.call(order: other_order).value).not_to eq described_class.call(order: order).value
      end
    end
  end
end
