module SpreeAvataxOfficial
  module Transactions
    class AmountRefundPresenter < CreatePresenter
      def initialize(order:, amount:, transaction_code:)
        @order            = order
        @amount           = amount.to_d
        @transaction_code = transaction_code
        @transaction_type = SpreeAvataxOfficial::Transaction::RETURN_INVOICE
      end

      # based on https://developer.avalara.com/api-reference/avatax/rest/v2/models/CreateTransactionModel/
      def to_json
        super.merge(date: formatted_date(Time.current))
      end

      private

      attr_reader :amount

      # Single tax-inclusive refund line. Avalara extracts tax at the order's
      # jurisdictional rates and enforces `lineAmount = taxableAmount + tax`,
      # so the split matches what Avalara would have produced for the
      # original sale at this address.
      def items_payload
        [{
          number:      "REFUND-#{transaction_code}",
          quantity:    1,
          amount:      -amount.to_f,
          taxCode:     refund_tax_code,
          discounted:  false,
          addresses:   refund_addresses_payload,
          taxIncluded: true,
          description: 'Refund'
        }]
      end

      def refund_tax_code
        order.line_items.first&.avatax_tax_code ||
          ::Spree::TaxCategory::DEFAULT_TAX_CODES['LineItem']
      end

      # The refund isn't tied to a specific shipment, so it carries the order's first
      # shipment's stock location as ShipFrom. There is no order-level fallback in the request.
      def refund_addresses_payload
        stock_location = order.shipments.first&.stock_location
        return {} if stock_location.nil?

        ship_from = SpreeAvataxOfficial::AddressPresenter.new(
          address:      {
            line1:      stock_location.address1.try(:first, 50),
            line2:      stock_location.address2.try(:first, 50),
            city:       stock_location.city,
            region:     stock_location.state.try(:abbr),
            country:    stock_location.country.try(:iso),
            postalCode: stock_location.zipcode
          },
          address_type: 'ShipFrom'
        ).to_json

        ship_to = SpreeAvataxOfficial::AddressPresenter.new(
          address:      order.tax_address,
          address_type: 'ShipTo'
        ).to_json

        ship_from.merge(ship_to)
      end
    end
  end
end
