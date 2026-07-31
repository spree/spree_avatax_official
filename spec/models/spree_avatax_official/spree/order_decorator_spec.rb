require 'spec_helper'

describe SpreeAvataxOfficial::Spree::OrderDecorator do
  let(:store)          { Spree::Store.default || create(:store) }
  let(:usa_address)    { create(:usa_address) }
  let(:europe_address) { create(:europe_address) }

  describe '#avatax_tax_inclusive?' do
    let!(:us_market) { create(:market, store: store, currency: 'USD', tax_inclusive: false, countries: [usa_address.country]) }
    let!(:eu_market) { create(:market, store: store, currency: 'EUR', tax_inclusive: true, countries: [europe_address.country]) }

    context 'when browsing an inclusive market but shipping to a non-inclusive destination' do
      let(:order) { create(:order, store: store, market: eu_market, ship_address: usa_address, bill_address: usa_address) }

      it 'follows the destination, not the browsing currency market' do
        expect(order.market).to eq(eu_market)
        expect(order.avatax_tax_market).to eq(us_market)
        expect(order.avatax_tax_inclusive?).to eq(false)
      end
    end

    context 'when browsing a non-inclusive market but shipping to an inclusive destination' do
      let(:order) { create(:order, store: store, market: us_market, ship_address: europe_address, bill_address: europe_address) }

      it 'follows the destination, not the browsing currency market' do
        expect(order.avatax_tax_market).to eq(eu_market)
        expect(order.avatax_tax_inclusive?).to eq(true)
      end
    end

    context 'when no market covers the destination' do
      let(:canada_address) { create(:canada_address) }
      let(:order) { create(:order, store: store, market: eu_market, ship_address: canada_address, bill_address: canada_address) }

      it 'falls back to the browsing market' do
        expect(order.avatax_tax_market).to eq(eu_market)
        expect(order.avatax_tax_inclusive?).to eq(true)
      end
    end
  end
end
