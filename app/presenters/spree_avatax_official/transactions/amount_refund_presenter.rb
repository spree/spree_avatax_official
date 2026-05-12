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
          addresses:   {},
          taxIncluded: true,
          description: 'Refund'
        }]
      end

      def refund_tax_code
        order.line_items.first&.avatax_tax_code ||
          ::Spree::TaxCategory::DEFAULT_TAX_CODES['LineItem']
      end
    end
  end
end
