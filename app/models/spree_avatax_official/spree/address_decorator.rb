module SpreeAvataxOfficial
  module Spree
    module AddressDecorator
      def self.prepended(base)
        base.around_save :recalculate_avatax_taxes
        base.const_set   'OBSERVABLE_FIELDS', %w[address1 address2 city zipcode state_id country_id].freeze
      end

      private

      def recalculate_avatax_taxes
        observed_fields_changed = self.class::OBSERVABLE_FIELDS & changed

        yield # around_save requires yield to perform save operation

        return unless observed_fields_changed.any? && persisted?

        address_sym = ::Spree::Config.tax_using_ship_address ? :ship_address : :bill_address
        order       = ::Spree::Order.incomplete.find_by(address_sym => self)

        return if order.blank?

        order.recalculate_avatax_taxes
      end
    end
  end
end

::Spree::Address.prepend ::SpreeAvataxOfficial::Spree::AddressDecorator
