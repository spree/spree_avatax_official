module SpreeAvataxOfficial
  module Transactions
    class AmountRefundPresenter
      def initialize(order:, amount:, transaction_code:)
        @order            = order
        @amount           = amount.to_d
        @transaction_code = transaction_code
      end

      # Based on: https://developer.avalara.com/api-reference/avatax/rest/v2/models/RefundTransactionModel/
      #
      # Avalara distributes refundPercentage across every line of the original
      # committed SalesInvoice. That preserves each line's taxCode, addresses,
      # and tax category in the resulting ReturnInvoice, and Avalara
      # automatically applies the original sale's tax date.
      def to_json
        {
          refundTransactionCode: transaction_code,
          referenceCode:         order.number,
          refundDate:            Time.current.strftime('%Y-%m-%d'),
          refundType:            'Percentage',
          refundPercentage:      refund_percentage
        }
      end

      private

      attr_reader :order, :amount, :transaction_code

      def refund_percentage
        (amount / order.total * 100).round(6)
      end
    end
  end
end
