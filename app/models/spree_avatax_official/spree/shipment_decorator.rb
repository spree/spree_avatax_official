module SpreeAvataxOfficial
  module Spree
    module ShipmentDecorator
      delegate :tax_zone, to: :order

      def self.prepended(base)
        base.include ::SpreeAvataxOfficial::HasUuid
      end

      def included_in_price
        order.market&.tax_inclusive || false
      end

      def tax_category
        selected_shipping_rate.try(:tax_rate).try(:tax_category) || shipping_method.try(:tax_category)
      end

      def avatax_tax_code
        tax_category.try(:tax_code).presence || ::Spree::TaxCategory::DEFAULT_TAX_CODES['Shipment']
      end

      def selected_shipping_rate_id=(id)
        super
        return if order.nil? || order.completed?

        order.recalculate_avatax_taxes
      end
    end
  end
end

::Spree::Shipment.prepend ::SpreeAvataxOfficial::Spree::ShipmentDecorator
