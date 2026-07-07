module SpreeAvataxOfficial
  module Transactions
    class CreatePresenter
      def initialize(order:, transaction_type:, transaction_code: order.number)
        @order            = order
        @transaction_type = transaction_type
        @transaction_code = transaction_code
      end

      # Based on: https://developer.avalara.com/api-reference/avatax/rest/v2/models/CreateTransactionModel/
      def to_json # rubocop:disable Metrics/MethodLength
        {
          type:                     transaction_type,
          code:                     transaction_code,
          referenceCode:            order.number,
          companyCode:              company_code,
          reportingLocationCode:    order.avatax_reporting_location_code,
          date:                     formatted_date(order_date),
          customerCode:             customer_code,
          lines:                    items_payload,
          commit:                   completed?(order),
          discount:                 order.avatax_discount_amount,
          currencyCode:             currency_code,
          purchaseOrderNo:          order.number,
          entityUseCode:            entity_use_code,
          exemptionNo:              exemption_no,
          businessIdentificationNo: business_identification_no
        }
      end

      delegate :user, to: :order

      private

      attr_reader :order, :transaction_type, :transaction_code

      def company_code
        order.avalara_integration&.preferred_company_code.presence || order.store.try(:avatax_company_code)
      end

      def entity_use_code
        user.try(:avatax_entity_use_code).try(:code)
      end

      # Free-text exemption certificate number. Per Avalara, *any* value in
      # this field flags the transaction as exempt. Often paired with an
      # entityUseCode (which provides the *reason*).
      # https://developer.avalara.com/avatax/handling-tax-exempt-customers/
      def exemption_no
        user.try(:exemption_number).presence
      end

      # The customer's VAT registration number. Used by AvaTax to detect
      # B2B EU transactions and apply the reverse-charge VAT rules. Sending
      # nil/blank skips the B2B determination (treated as B2C).
      def business_identification_no
        user.try(:vat_id).presence
      end

      def formatted_date(date)
        date.strftime('%Y-%m-%d')
      end

      def order_date
        order.completed_at || order.updated_at
      end

      def customer_code
        user.try(:email) || order.email
      end

      def items_payload
        order.taxable_items.map { |item| SpreeAvataxOfficial::ItemPresenter.new(item: item).to_json }
      end

      def completed?(order)
        order.completed_at.present?
      end

      def currency_code
        order.currency || ::Spree::Config[:currency]
      end
    end
  end
end
