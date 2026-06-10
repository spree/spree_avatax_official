require 'spec_helper'

describe Spree::Order do
  describe 'associations' do
    let(:order) { create(:order) }

    describe 'avatax_sales_invoice_transaction' do
      let!(:return_invoice_transaction) { create(:spree_avatax_official_transaction, :return_invoice, order: order) }
      let!(:sales_invoice_transaction)  { create(:spree_avatax_official_transaction, order: order) }

      it 'returns SpreeAvataxOfficial::Transaction object with transaction_type: SalesInvoice' do
        expect(order.avatax_sales_invoice_transaction).to eq sales_invoice_transaction
      end
    end
  end

  describe '#avatax_reporting_location_code' do
    let(:order) { create(:order) }

    context 'without shipments' do
      it 'returns nil' do
        expect(order.avatax_reporting_location_code).to be_nil
      end
    end

    context 'when the order ships from multiple stock locations with codes' do
      let(:location_a) { create(:stock_location, name: 'Avatax Loc A', code: 'A') }
      let(:location_b) { create(:stock_location, name: 'Avatax Loc B', code: 'B') }

      before do
        create(:avatax_shipment, order: order, stock_location: location_a)
        create(:avatax_shipment, order: order, stock_location: location_b)
        order.shipments.reload
      end

      it 'returns the comma-separated codes of every shipment stock location' do
        expect(order.avatax_reporting_location_code).to eq 'A,B'
      end
    end

    context 'when the shipment stock location has no code' do
      let(:location) { create(:stock_location, name: 'Avatax Loc C', code: nil) }

      before do
        create(:avatax_shipment, order: order, stock_location: location)
        order.shipments.reload
      end

      it 'returns nil' do
        expect(order.avatax_reporting_location_code).to be_nil
      end
    end
  end

  describe '#cancel', :avalara_integration do
    let!(:avatax_tax_rate) { create(:avatax_tax_rate) }
    let(:order) { create(:order, ship_address: create(:usa_address)) }

    before do
      create(:line_item, price: 10.0, quantity: 1, order: order)
      order.update(state: :complete, completed_at: Time.current)
    end

    it 'calls void service' do
      expect(SpreeAvataxOfficial::Transactions::VoidService).to receive(:call).at_least(:once)

      order.cancel
    end
  end

  describe '#taxable_items' do
    let(:order) { create(:shipped_order, line_items_count: 2) }

    it 'returns array of shipments and line items' do
      expect(order.taxable_items).to eq [order.line_items.first, order.line_items.last, order.shipments.first]
    end
  end

  describe '#complete', :avalara_integration do
    let(:order) do
      VCR.use_cassette('spree_order/order_transition_to_completed') do
        create(:avatax_order, line_items_count: 1, ship_address: create(:usa_address)).tap do |order|
          order.payments << create(:payment)

          order.next!
          # Unfortunetly state machine does not allow me to stub create_proposed_shipments method
          # Stubbing results with `Wrong number of arguments. Expected 0, got 1.` without stacktrace
          create(:avatax_shipment, order: order)
          order.update(state: 'delivery')
          order.reload
          2.times { order.next! }
        end
      end
    end

    context 'commit transaction enabled' do
      before { update_avalara_setting(:commit_transaction_enabled, true) }

      it 'creates a commited SalesInvoice transaction' do
        expect(order.state).to eq 'confirm'

        VCR.use_cassette('spree_order/complete_order') do
          expect { order.next! }.to change { order.avatax_transactions.count }.by(1)
        end
      end
    end

    context 'commit transaction disabled' do
      before { update_avalara_setting(:commit_transaction_enabled, false) }
      after { update_avalara_setting(:commit_transaction_enabled, true) }

      it 'doesnt create a commited SalesInvoice transaction' do
        expect(order.state).to eq 'confirm'

        VCR.use_cassette('spree_order/complete_order_no_transaction') do
          expect { order.next! }.to_not change { order.avatax_transactions.count }
        end
      end
    end
  end

  describe 'tax estimation triggering', :avalara_integration do
    let(:order) { create(:avatax_order, with_shipment: true, ship_address: create(:usa_address)) }
    let(:line_item) { order.line_items.first }
    let(:shipment) { order.shipments.first }
    let(:tax_adjustment) { line_item.adjustments.tax.first }

    before do
      VCR.use_cassette('spree_order/simple_order_with_single_line_item_and_shipment') do
        create(:line_item, price: 10.0, quantity: 1, order: order)

        order.reload
        order.updater.update
      end
    end

    context 'when line item discount promotion is applied' do
      let(:promotion) { create(:promotion, :with_line_item_adjustment, adjustment_rate: 5, code: 'promotion_code') }

      it 'triggers tax estimation' do
        expect(order.total).to eq 16.2

        VCR.use_cassette('spree_order/order_with_line_item_adjustment') do
          order.coupon_code = promotion.code
          Spree::PromotionHandler::Coupon.new(order).apply

          order.updater.update
        end

        expect(order.total).to eq 10.8
        expect(line_item.reload.additional_tax_total).to eq 0.4
        expect(shipment.reload.additional_tax_total).to eq 0.4
        expect(tax_adjustment.amount).to eq 0.4
      end
    end

    context 'when order discount promotion is applied' do
      let(:promotion) { create(:promotion, :avatax_with_order_adjustment, weighted_order_adjustment_amount: 5.0, code: 'promotion_code') }

      it 'triggers tax estimation' do
        expect(order.total).to eq 16.2

        VCR.use_cassette('spree_order/order_with_order_adjustment') do
          order.coupon_code = promotion.code
          Spree::PromotionHandler::Coupon.new(order).apply

          order.updater.update
        end

        expect(order.total).to eq 10.8
        expect(shipment.reload.additional_tax_total).to eq 0.4
        expect(tax_adjustment.amount).to eq 0.4
      end
    end

    context 'when shipping address is changed', if: (::Gem::Version.new(::Spree.version) >= ::Gem::Version.new('3.0.0')) do
      let(:california_address) { create(:usa_address, :from_california) }

      it 'triggers tax estimation' do
        expect(order.total).to eq 16.2

        VCR.use_cassette('spree_order/california_order') do
          order.tax_address.update(
              address1: california_address.address1,
              address2: california_address.address2,
              city:     california_address.city,
              zipcode:  california_address.zipcode,
              state_id: california_address.state_id
          )
          california_address.run_callbacks(:save)
        end

        expect(order.reload.total).to eq 15.73
        expect(line_item.reload.additional_tax_total).to eq 0.73
        # California does not charge shipping tax
        # https://www.avalara.com/us/en/blog/2016/01/do-i-charge-tax-on-shipping-costs-in-california.html
        expect(shipment.reload.additional_tax_total).to eq 0

        expect(tax_adjustment.amount).to eq 0.73
      end
    end
  end

  describe '#validate_tax_address', :avalara_integration do
    let(:order) { create(:order_with_line_items, ship_address: ship_address, state: :address) }

    before { update_avalara_setting(:address_validation_enabled, true) }
    after { update_avalara_setting(:address_validation_enabled, false) }

    context 'when address is invalid' do
      let(:ship_address) { create(:invalid_usa_address) }

      it 'does not change order state to delivery and adds an error' do
        # Suppress factory-chain tax recalc; only the address-validation
        # call should be captured by the cassette.
        avalara_integration.update!(active: false)
        order
        avalara_integration.update!(active: true)

        VCR.use_cassette('spree_avatax_official/address/validate_failure') do
          expect { order.next! }.to raise_error StateMachines::InvalidTransition
          expect(order.errors.count).to eq 1
          expect(order.state).to eq 'address'
        end
      end
    end

    context 'when address is valid' do
      let(:ship_address) { create(:usa_address) }

      it 'changes state from address to delivery' do
        avalara_integration.update!(active: false)
        order
        avalara_integration.update!(active: true)

        VCR.use_cassette('spree_avatax_official/address/validate_success') do
          expect { order.next! }.to change(order, :state).to 'delivery'
        end
      end
    end

    context 'when there is no address' do
      let(:ship_address) { nil }

      it 'returns truthy without raising' do
        avalara_integration.update!(active: false)
        order
        avalara_integration.update!(active: true)

        expect(order.tax_address).to be_nil
        expect { order.validate_tax_address }.not_to raise_error
        expect(order.errors).to be_empty
      end
    end
  end
end
