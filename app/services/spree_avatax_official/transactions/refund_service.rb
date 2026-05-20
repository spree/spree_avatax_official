module SpreeAvataxOfficial
  module Transactions
    class RefundService < SpreeAvataxOfficial::Base
      def call(refundable:)
        if standalone_refund?(refundable)
          create_amount_refund(refundable)
        elsif full_refund?(refundable)
          create_full_refund(refundable)
        else
          create_partial_refund(refundable)
        end
      end

      private

      def standalone_refund?(refundable)
        refundable.is_a?(::Spree::Refund) && refundable.reimbursement.blank?
      end

      def create_amount_refund(refundable)
        if refundable.amount >= refundable.order.total
          create_full_refund(refundable)
        else
          SpreeAvataxOfficial::Transactions::AmountRefundService.call(
            **refundable_params(refundable).merge(amount: refundable.amount)
          )
        end
      end

      def full_refund?(refundable)
        refundable.order_inventory_units == inventory_units(refundable)
      end

      def refundable_class(refundable)
        @refundable_class ||= refundable.class.name.demodulize
      end

      def inventory_units(refundable)
        @inventory_units ||= case refundable_class(refundable)
                             when 'ReturnAuthorization'
                               refundable.inventory_units
                             when 'Refund'
                               refundable.reimbursement.return_items.map(&:inventory_unit)
                             end
      end

      def create_partial_refund(refundable)
        SpreeAvataxOfficial::Transactions::PartialRefundService.call(
          **refundable_params(refundable).merge(
            refund_items: refund_items(refundable)
          )
        )
      end

      def refund_items(refundable)
        inventory_units(refundable).group_by(&:line_item).reduce({}) do |ids, (line_item, units)|
          ids.merge!(line_item => [line_item_quantity(units), -1 * line_item_amount(refundable, units)])
        end
      end

      def refundable_params(refundable)
        {
          order:            refundable.order,
          transaction_code: refund_transaction_code(refundable.order_number, refundable.id)
        }
      end

      def line_item_quantity(units)
        return units.count unless units.first.respond_to?(:quantity)

        units.sum(&:quantity)
      end

      def line_item_amount(refundable, units)
        case refundable_class(refundable)
        when 'ReturnAuthorization'
          amount_per_unit(refundable, units) * units.count
        when 'Refund'
          items(refundable, units).sum(&:pre_tax_amount)
        end
      end

      def amount_per_unit(refundable, units)
        items(refundable, units).sum(&:pre_tax_amount) / items(refundable, units).sum(&:quantity)
      end

      def items(refundable, units)
        case refundable_class(refundable)
        when 'ReturnAuthorization'
          units.map(&:line_item).uniq
        when 'Refund'
          units.flat_map(&:return_items).uniq
        end
      end

      def create_full_refund(refundable)
        SpreeAvataxOfficial::Transactions::FullRefundService.call(
          **refundable_params(refundable)
        )
      end
    end
  end
end
