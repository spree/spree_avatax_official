module SpreeAvataxOfficial
  module Spree
    module OrderDecorator
      def self.prepended(base)
        base.register_update_hook :recalculate_avatax_taxes

        base.has_many :avatax_transactions, class_name: 'SpreeAvataxOfficial::Transaction'
        base.has_many :stock_locations, through: :shipments

        base.has_one :avatax_sales_invoice_transaction, -> { where(transaction_type: 'SalesInvoice') },
                     class_name: 'SpreeAvataxOfficial::Transaction',
                     inverse_of: :order

        base.state_machine.before_transition to: :delivery, do: :validate_tax_address, if: :address_validation_enabled?
        base.state_machine.after_transition to: :canceled, do: :void_in_avatax
        base.state_machine.after_transition to: :complete, do: :commit_in_avatax

        # Recalculate when the order's address changes (selecting an existing address from the address book).
        base.after_update :recalculate_avatax_taxes_on_address_change
      end

      def avalara_integration
        store&.integrations&.active&.find_by(type: 'Spree::Integrations::Avalara')
      end

      def avatax_enabled?
        avalara_integration.present?
      end

      def taxable_items
        line_items.reload + shipments.reload
      end

      def avatax_tax_calculation_required?
        return false unless tax_address&.persisted?
        return false unless line_items.any?
        return false if delivery_required? && shipments.empty?

        true
      end

      def avatax_discount_amount
        adjustments.promotion.eligible.sum(:amount).abs
      end

      def line_items_discounted_in_avatax?
        adjustments.promotion.eligible.any?
      end

      # Distinct, comma-joined `code`s of every stock location the order ships from,
      # sent to Avalara as the transaction-level `reportingLocationCode`.
      # @return [String, nil]
      def avatax_reporting_location_code
        stock_locations.filter_map { |stock_location| stock_location.code.presence }.uniq.join(',').presence
      end

      def tax_address_symbol
        ::Spree::Config.tax_using_ship_address ? :ship_address : :bill_address
      end

      # We need to override this so the default Spree tax calculation is not triggered.
      # The actual tax calculation by Avalara is done in #recalculate_avatax_taxes
      def create_tax_charge!
        return if avatax_enabled?

        super
      end

      def recalculate_avatax_taxes
        return unless avatax_enabled?

        SpreeAvataxOfficial::CreateTaxAdjustmentsService.call(order: self)
        update_totals
        persist_totals
      end

      def validate_tax_address
        response = SpreeAvataxOfficial::Address::Validate.call(
          address: tax_address,
          order: self
        )

        return if response.success?

        messages = response.value&.body&.dig('messages')
        error_message = messages.present? ? messages.map { |message| message['summary'] }.join('. ') : 'Address validation failed'

        errors.add(:base, error_message)

        false
      end

      def address_validation_enabled?
        avalara_integration&.preferred_address_validation_enabled || false
      end

      private

      def recalculate_avatax_taxes_on_address_change
        return unless avatax_enabled?
        return unless (%w[ship_address_id bill_address_id] & saved_changes.keys).any?

        recalculate_avatax_taxes
      end

      def commit_in_avatax
        return unless avatax_enabled? && avalara_integration.preferred_commit_transaction_enabled

        SpreeAvataxOfficial::Transactions::CreateService.call(order: self)
      end

      def void_in_avatax
        return unless avatax_enabled?

        SpreeAvataxOfficial::Transactions::VoidService.call(order: self)
      end
    end
  end
end

::Spree::Order.prepend ::SpreeAvataxOfficial::Spree::OrderDecorator
