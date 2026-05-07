require 'spec_helper'

describe SpreeAvataxOfficial::CreateTaxAdjustmentsService, :avalara_integration do
  subject { described_class.call(order: order) }

  let(:usa_address) { create(:usa_address) }

  describe '#call' do
    context 'with external tax' do
      context 'with single line item order' do
        let(:order) { create(:avatax_order, line_items_count: 1, ship_address: usa_address) }
        let(:line_item) { order.line_items.first }
        let(:tax_adjustment) { line_item.adjustments.tax.first }

        context 'with_tax_excluded' do
          it 'creates tax rates and tax adjustments for all taxable items' do
            result = nil

            VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_excluded/single_line_item') do
              result = subject

              order.updater.update
            end

            expect(result.success?).to eq true
            expect(order.total).to eq 10.8
            expect(order.additional_tax_total).to eq 0.8
            expect(line_item.reload.additional_tax_total).to eq 0.8
            expect(tax_adjustment.amount).to eq 0.8
            expect(tax_adjustment.source_type).to eq 'Spree::TaxRate'
          end
        end

        context 'with_tax_included' do
          it 'creates tax rates and tax adjustments for all taxable items' do
            result = nil

            VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_included/single_line_item') do
              enable_tax_inclusive_for_order(order)
              result = subject

              order.updater.update
            end

            expect(result.success?).to eq true
            expect(order.total).to eq 10
            expect(order.included_tax_total).to eq 0.75
            expect(line_item.reload.included_tax_total).to eq 0.75
            expect(tax_adjustment.amount).to eq 0.75
            expect(tax_adjustment.source_type).to eq 'Spree::TaxRate'
          end
        end
      end

      context 'with single line item and and shipment' do
        let(:shipment) { order.shipments.first }
        let(:tax_adjustment) { shipment.adjustments.tax.first }

        context 'when shipping method has tax category' do
          let(:order) { create(:avatax_order, with_shipment: true, line_items_count: 1, ship_address: usa_address) }

          context 'with tax excluded' do
            it 'creates tax rates and tax adjustments' do
              result = nil

              VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_excluded/line_item_and_shipment') do
                result = subject

                order.updater.update
              end

              expect(result.success?).to eq true
              expect(order.total).to eq 16.2
              expect(order.additional_tax_total).to eq 1.2
              expect(shipment.reload.additional_tax_total).to eq 0.4
              expect(tax_adjustment.amount).to eq 0.4
              expect(tax_adjustment.source_type).to eq 'Spree::TaxRate'
            end
          end

          context 'with tax included' do
            it 'creates tax rates and tax adjustments' do
              result = nil

              VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_included/line_item_and_shipment') do
                enable_tax_inclusive_for_order(order)
                result = subject

                order.updater.update
              end

              expect(result.success?).to eq true
              expect(order.total).to eq 15.0
              expect(order.included_tax_total).to eq 1.12
              expect(order.additional_tax_total).to eq 0
              expect(shipment.reload.included_tax_total).to eq 0.37
              expect(tax_adjustment.source_type).to eq 'Spree::TaxRate'
            end
          end
        end

        context 'when shipping method does NOT have tax category' do
          let(:order) { create(:avatax_order, with_shipment: true, with_shipping_tax_category: false, line_items_count: 1, ship_address: usa_address) } # rubocop:disable Metrics/LineLength

          it 'creates tax rates and tax adjustments only for line items' do
            result = nil

            VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_excluded/line_item_and_shipment') do
              result = subject

              order.updater.update
            end

            expect(result.success?).to eq true
            expect(order.total).to eq 15.8
            expect(order.additional_tax_total).to eq 0.8
            expect(shipment.reload.additional_tax_total).to eq 0
          end
        end

        context 'when SpreeAvataxOfficial::Config.show_rate_in label is true' do
          let(:order) { create(:avatax_order, with_shipment: true, line_items_count: 1, ship_address: usa_address) }
          let(:line_item_tax_adjustment) { order.line_items.first.adjustments.tax.first }
          let(:shipment_tax_adjustment) { order.shipments.first.adjustments.tax.first }

          before { update_avalara_setting(:show_rate_in_label, true) }
          after { update_avalara_setting(:show_rate_in_label, false) }

          it 'sets adjustments labels with percentage tax amount' do
            result = nil

            VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_excluded/line_item_and_shipment') do
              result = subject

              order.updater.update
            end

            expect(result.success?).to eq true
            expect(line_item_tax_adjustment.source.amount).to eq 0.08
            expect(line_item_tax_adjustment.label).to eq 'Sales Tax (8%)'
            expect(shipment_tax_adjustment.source.amount).to eq 0.08
            expect(shipment_tax_adjustment.label).to eq 'Shipping Tax (8%)'
          end
        end

        context 'when stock location has different address then order tax address' do
          let(:california_address)       { create(:usa_address, :from_california) }
          let(:order)                    { create(:avatax_order, with_shipment: true, line_items_count: 1, ship_address: usa_address) }
          let(:line_item)                { order.line_items.first }
          let(:line_item_tax_adjustment) { line_item.adjustments.tax.first }
          let(:shipment_tax_adjustment)  { order.shipments.first.adjustments.tax.first }

          it 'creates tax rates and tax adjustments' do
            result = nil

            VCR.use_cassette('spree_avatax_official/create_tax_adjustments/californian_stock_location') do
              line_item.inventory_units.first.shipment.stock_location.update(
                name:     'California Warehouse',
                address1: california_address.address1,
                address2: california_address.address2,
                city:     california_address.city,
                zipcode:  california_address.zipcode,
                state_id: california_address.state_id
              )

              result = subject

              order.updater.update
            end

            expect(result.success?).to eq true
            expect(order.total).to eq 16.2
            expect(order.additional_tax_total).to eq 1.2
          end
        end
      end

      context 'with multiple line items with multiple quantity' do
        let(:order) { create(:avatax_order, ship_address: usa_address) }
        let(:first_line_item) { order.line_items.first }
        let(:second_line_item) { order.line_items.second }

        context 'with tax excluded' do
          it 'creates tax rates and tax adjustments' do
            result = nil

            VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_excluded/multiple_line_items_multiple_quantity') do
              create(:line_item, id: 1, price: 10.0, quantity: 2, order: order)
              create(:line_item, id: 2, price: 10.0, quantity: 3, order: order, avatax_uuid: '50f0c7ba-0c5f-4479-a24a-3de192354004')

              order.reload
              result = subject

              order.updater.update
            end

            expect(result.success?).to eq true
            expect(order.total).to eq 54.0
            expect(order.additional_tax_total).to eq 4.0
            expect(first_line_item.reload.additional_tax_total).to eq 1.6
            expect(second_line_item.reload.additional_tax_total).to eq 2.4
          end
        end

        context 'with tax included' do
          it 'creates tax rates and tax adjustments' do
            result = nil

            VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_included/multiple_line_items_multiple_quantity') do
              enable_tax_inclusive_for_order(order)
              create(:line_item, id: 1, price: 10.0, quantity: 2, order: order)
              create(:line_item, id: 2, price: 10.0, quantity: 3, order: order, avatax_uuid: '50f0c7ba-0c5f-4479-a24a-3de192354004')

              order.reload
              result = subject

              order.updater.update
            end

            expect(result.success?).to eq true
            expect(order.total).to eq 50.0
            expect(order.included_tax_total).to eq 3.71
            expect(first_line_item.reload.included_tax_total).to eq 1.48
            expect(second_line_item.reload.included_tax_total).to eq 2.23
          end
        end
      end

      context 'with promotion that adjusts line items' do
        let(:order) { create(:avatax_order, ship_address: usa_address) }
        let(:first_line_item) { order.line_items.first }
        let(:second_line_item) { order.line_items.second }
        let(:promotion) { create(:promotion, :with_line_item_adjustment, adjustment_rate: 10, code: 'promotion_code') }

        context 'with tax excluded' do
          it 'creates tax rates and tax adjustments' do
            result = nil

            VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_excluded/line_item_adjustment_promotion') do
              create(:line_item, id: 1, price: 10.0, quantity: 4, order: order)
              create(:line_item, id: 2, price: 10.0, quantity: 3, order: order, avatax_uuid: 'bf57f52a-2ab3-44bc-8be3-8f99ecccd196')

              order.reload
              order.updater.update
              order.coupon_code = promotion.code
              Spree::PromotionHandler::Coupon.new(order).apply

              result = subject

              order.updater.update
            end

            expect(result.success?).to eq true
            expect(order.total).to eq 54.0
            expect(order.additional_tax_total).to eq 4.0
            expect(first_line_item.reload.additional_tax_total).to eq 2.4
            expect(second_line_item.reload.additional_tax_total).to eq 1.6
          end
        end

        context 'with tax included' do
          it 'creates tax rates and tax adjustments' do
            result = nil

            VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_included/line_item_adjustment_promotion') do
              enable_tax_inclusive_for_order(order)
              create(:line_item, id: 1, price: 10.0, quantity: 4, order: order)
              create(:line_item, id: 2, price: 10.0, quantity: 3, order: order, avatax_uuid: 'bf57f52a-2ab3-44bc-8be3-8f99ecccd196')

              order.reload
              order.updater.update
              order.coupon_code = promotion.code
              Spree::PromotionHandler::Coupon.new(order).apply

              result = subject

              order.updater.update
            end

            expect(result.success?).to eq true
            expect(order.total).to eq 50.0
            expect(order.included_tax_total).to eq 3.71
            expect(first_line_item.reload.included_tax_total).to eq 2.23
            expect(second_line_item.reload.included_tax_total).to eq 1.48
          end
        end
      end

      context 'with promotion that adjusts shipment' do
        let(:order) { create(:avatax_order, with_shipment: true, line_items_count: 1, ship_address: usa_address) }
        let(:first_line_item) { order.line_items.first }
        let(:shipment) { order.shipments.first }
        let(:promotion) { create(:free_shipping_promotion, code: 'promotion_code') }

        it 'creates tax rates and tax adjustments' do
          result = nil

          VCR.use_cassette('spree_avatax_official/create_tax_adjustments/shipment_adjustment_promotion') do
            order.coupon_code = promotion.code
            Spree::PromotionHandler::Coupon.new(order).apply

            result = subject

            order.updater.update
          end

          expect(result.success?).to eq true

          expect(order.total).to eq 10.8
          expect(order.additional_tax_total).to eq 0.8
          expect(shipment.additional_tax_total).to eq 0.0
          expect(shipment.discounted_cost).to eq 0.0
        end
      end

      context 'with promotion that adjusts whole order' do
        let(:order) { create(:avatax_order, with_shipment: true, ship_address: usa_address) }
        let(:first_line_item) { order.line_items.first }
        let(:second_line_item) { order.line_items.second }
        let(:shipment) { order.shipments.first }
        let(:promotion) { create(:promotion, :avatax_with_order_adjustment, weighted_order_adjustment_amount: 20.0, code: 'promotion_code') }

        it 'creates tax rates and tax adjustments' do
          result = nil

          VCR.use_cassette('spree_avatax_official/create_tax_adjustments/order_adjustment_promotion') do
            create(:line_item, id: 1, price: 10.0, quantity: 4, order: order)
            create(:line_item, id: 2, price: 10.0, quantity: 3, order: order, avatax_uuid: 'be393e03-c530-4d31-bea7-f01b39496568')

            order.reload.updater.update
            order.coupon_code = promotion.code
            Spree::PromotionHandler::Coupon.new(order).apply

            result = subject

            order.updater.update
          end

          expect(result.success?).to eq true
          expect(order.total).to eq 59.4
          expect(order.additional_tax_total).to eq 4.4
          expect(first_line_item.reload.additional_tax_total).to eq 2.28 # I would expect 2.4 but AvaTax applies discount proportionaly to price
          expect(second_line_item.reload.additional_tax_total).to eq 1.72 # I would expect 1.6 but AvaTax applies discount proportionaly to price
          expect(shipment.reload.additional_tax_total).to eq 0.4 # Shipment tax is not affected by order level promotions
        end
      end
    end

    context 'completed order with single line item and shipment' do
      let(:order) { create(:avatax_order, :completed, number: 'R820471933', with_shipment: true, line_items_count: 1, ship_address: usa_address) }
      let(:line_item) { order.line_items.first }
      let(:shipment) { order.shipments.first }
      let(:invoice_transaction) { order.reload.avatax_sales_invoice_transaction }

      before do
        VCR.use_cassette('spree_avatax_official/create_tax_adjustments/simple_completed_order') do
          order.reload

          described_class.call(order: order)
          order.updater.update
        end
      end

      it 'updates tax rates and tax adjustments' do
        expect(invoice_transaction).to be_present
        expect(order.total).to eq 21.6
        expect(order.additional_tax_total).to eq 1.6

        result = nil
        VCR.use_cassette('spree_avatax_official/create_tax_adjustments/completed_order_line_item_update') do
          line_item.update(quantity: 2)
          result = subject
          order.updater.update
        end

        expect(result.success?).to eq true
        expect(order.total).to eq 32.4
        expect(order.additional_tax_total).to eq 2.4
      end
    end

    context 'with canceled order' do
      let(:order) { create(:order, state: :canceled) }

      it 'returns failure' do
        result = subject

        expect(result.failure?).to eq true
        expect(result.value).to eq 'Cannot calculate tax for a canceled order'
      end
    end

    context 'with incorrect address' do
      let(:invalid_address) { create(:usa_address, address1: 'Invalid street', city: 'Invalid city', zipcode: '00000') }
      let(:order) { create(:avatax_order, line_items_count: 1, ship_address: invalid_address) }

      it 'returns failure' do
        result = nil
        VCR.use_cassette('spree_avatax_official/create_tax_adjustments/with_incorrect_address') do
          result = subject
        end

        expect(result.failure?).to eq true
        expect(result.value).to eq '300 - Tax calculation cannot be determined. Zip is not valid for the state. - ' \
                                   'The provided address contains a postal code and state combination that is not valid..'
      end
    end

    context 'when tax address is NOT persisted' do
      let(:tax_address) { build(:address) }
      let(:order)       { create(:order_with_line_items, number: 'non-existing-number') }

      it 'returns failure' do
        VCR.use_cassette('spree_avatax_official/create_tax_adjustments/tax_address_not_persisted') do
          allow(order).to receive(:tax_address).and_return(tax_address)

          expect(subject.success?).to eq false
        end
      end
    end

    context 'when avatax_response is false' do
      let(:order)        { create(:completed_order_with_totals) }
      let(:false_result) { Spree::ServiceModule::Result.new(false, false) }

      before do
        allow(SpreeAvataxOfficial::Transactions::FindOrderTransactionService).to receive(:call).and_return(false_result)
        allow(SpreeAvataxOfficial::Transactions::CreateService).to receive(:call).and_return(false_result)
      end

      it 'creates avatax transaction' do
        expect(subject.success?).to eq false
        expect(subject.value).to    eq 'AvaTax failed to calculate tax'
      end
    end
  end
end
