module SpreeAvataxOfficial
  module Spree
    module LineItemDecorator
      delegate :tax_zone, to: :order

      def self.prepended(base)
        base.include ::SpreeAvataxOfficial::HasUuid
      end

      def included_in_price
        order.market&.tax_inclusive || false
      end

      def update_tax_charge
        return super unless order.avatax_enabled?

        SpreeAvataxOfficial::CreateTaxAdjustmentsService.call(order: order)
      end

      def avatax_tax_code
        tax_category.try(:tax_code).presence || ::Spree::TaxCategory::DEFAULT_TAX_CODES['LineItem']
      end
    end
  end
end

::Spree::LineItem.prepend ::SpreeAvataxOfficial::Spree::LineItemDecorator
