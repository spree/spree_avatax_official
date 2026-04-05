module SpreeAvataxOfficial
  module Spree
    module RefundDecorator
      def self.prepended(base)
        base.after_create :refund_in_avatax

        base.delegate :order,                    to: :payment
        base.delegate :inventory_units, :number, to: :order, prefix: true
      end

      private

      def refund_in_avatax
        return unless order.avatax_enabled? && order.avalara_integration.preferred_commit_transaction_enabled

        SpreeAvataxOfficial::Transactions::RefundService.call(refundable: self)
      end
    end
  end
end

::Spree::Refund.prepend ::SpreeAvataxOfficial::Spree::RefundDecorator
