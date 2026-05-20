require 'spec_helper'

describe Spree::Shipment do
  let(:shipment) { create(:shipment) }

  describe '#avatax_number' do
    it 'returns shipment id with avatax code' do
      expect(shipment.avatax_number).to eq "FR-#{shipment.avatax_uuid}"
    end
  end

  describe '#selected_shipping_rate_id=', :avalara_integration do
    let(:order)        { create(:avatax_order, with_shipment: true, line_items_count: 1, ship_address: create(:usa_address)) }
    let(:shipment)     { order.shipments.first }
    let(:other_method) { create(:avatax_shipping_method, name: 'AvaTax Express') }
    let(:other_rate)   { shipment.shipping_rates.create!(shipping_method: other_method, cost: 12.0) }

    context 'when the order is in checkout' do
      it 'recalculates tax for the newly-selected rate' do
        VCR.use_cassette('spree_avatax_official/spree/shipment/selected_shipping_rate_change') do
          original_tax = shipment.reload.additional_tax_total

          shipment.selected_shipping_rate_id = other_rate.id

          expect(shipment.reload.cost).to eq 12.0
          expect(shipment.reload.additional_tax_total).not_to eq original_tax
        end
      end
    end

    context 'when the order is completed' do
      it 'does not recalculate tax' do
        VCR.use_cassette('spree_avatax_official/spree/shipment/selected_shipping_rate_change_completed') do
          original_tax = shipment.reload.additional_tax_total
          order.update_columns(state: 'complete', completed_at: Time.current)

          shipment.selected_shipping_rate_id = other_rate.id

          expect(shipment.reload.additional_tax_total).to eq original_tax
        end
      end
    end
  end
end
