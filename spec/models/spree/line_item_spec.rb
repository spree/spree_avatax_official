require 'spec_helper'

describe Spree::LineItem do
  describe '#avatax_number' do
    let(:line_item) { create(:line_item) }

    it 'returns line item id with avatax code' do
      expect(line_item.avatax_number).to eq "LI-#{line_item.avatax_uuid}"
    end
  end

  describe '#update_tax_charge' do
    context 'with AvaTax tax calculcation', :avalara_integration do
      let(:order) { create(:avatax_order, ship_address: create(:usa_address)) }
      let(:line_item) { order.line_items.first }

      before do
        VCR.use_cassette('spree_order/update_tax_charge/create_line_item') do
          create(:line_item, price: 10.0, quantity: 2, order: order)

          order.reload
          order.updater.update
        end
      end

      context 'when line item is created' do
        it 'updates line item and order tax' do
          expect(order.total).to eq 21.6
          expect(order.additional_tax_total).to eq 1.6
          expect(line_item.reload.additional_tax_total).to eq 1.6
        end
      end

      context 'when line item quantity is increased' do
        it 'updates line item and order tax' do
          VCR.use_cassette('spree_line_item/update_tax_charge/increase_quantity') do
            line_item.update(quantity: 3)

            order.reload
            order.updater.update
          end

          expect(order.total).to eq 32.4
          expect(order.additional_tax_total).to eq 2.4
          expect(line_item.reload.additional_tax_total).to eq 2.4
        end
      end

      context 'when line item quantity is decreased' do
        it 'updates line item and order tax' do
          VCR.use_cassette('spree_line_item/update_tax_charge/decrease_quantity') do
            line_item.update(quantity: 1)

            order.reload
            order.updater.update
          end

          expect(order.total).to eq 10.8
          expect(order.additional_tax_total).to eq 0.8
          expect(line_item.reload.additional_tax_total).to eq 0.8
        end
      end

      context 'when line item is destroyed' do
        it 'updates line item and order tax' do
          line_item.destroy

          order.reload.updater.update

          expect(order.total).to eq 0
          expect(Spree::Adjustment.tax.count).to eq 0
        end
      end
    end
  end
end
