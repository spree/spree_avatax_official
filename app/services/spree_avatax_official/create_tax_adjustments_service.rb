module SpreeAvataxOfficial
  class CreateTaxAdjustmentsService < SpreeAvataxOfficial::Base
    include SpreeAvataxOfficial::TaxAdjustmentLabelHelper

    def call(order:) # rubocop:disable Metrics/AbcSize
      return failure(::Spree.t('spree_avatax_official.create_tax_adjustments.order_canceled')) if order.canceled?

      order.all_adjustments.tax.destroy_all

      return failure(::Spree.t('spree_avatax_official.create_tax_adjustments.tax_calculation_unnecessary')) unless order.avatax_tax_calculation_required?

      transaction_cache_key = SpreeAvataxOfficial::GenerateTransactionCacheKeyService.call(order: order).value

      avatax_response       = Rails.cache.fetch(transaction_cache_key, expires_in: 5.minutes) do
        send_transaction_to_avatax(order)
      end

      return failure(build_error_message_from_response(avatax_response.value)) if avatax_failed_response?(avatax_response)

      process_avatax_items(order, avatax_response.value['lines'])

      success(true)
    end

    private

    def send_transaction_to_avatax(order)
      if order.avatax_sales_invoice_transaction.present?
        SpreeAvataxOfficial::Transactions::AdjustService.call(
          order:                  order,
          adjustment_reason:      SpreeAvataxOfficial::Transaction::DEFAULT_ADJUSTMENT_REASON,
          adjustment_description: ::Spree.t('spree_avatax_official.create_tax_adjustments.adjustment_description')
        )
      else
        SpreeAvataxOfficial::Transactions::CreateService.call(order: order)
      end
    end

    def avatax_failed_response?(avatax_response)
      avatax_response.failure? || avatax_response.value['totalTax'].zero?
    end

    def process_avatax_items(order, avatax_items)
      avatax_items.each { |avatax_item| process_avatax_item(order, avatax_item) }
    end

    def process_avatax_item(order, avatax_item)
      tax_amount = avatax_item['taxCalculated']

      return if tax_amount.zero?

      item_suffix = avatax_item['lineNumber'].slice(0..2)
      item_id     = avatax_item['lineNumber'].slice(3..-1)
      item        = find_item(order, item_id, item_suffix)

      return if item.nil? || item.tax_category.nil?

      tax_rate = find_or_create_tax_rate(item, avatax_item)

      store_pre_tax_amount(item, tax_rate, tax_amount)

      create_tax_adjustment(item, tax_rate, tax_amount)
    end

    def find_item(order, uuid, suffix)
      case suffix
      when 'LI-'
        order.line_items.find_by(avatax_uuid: uuid)
      when 'FR-'
        order.shipments.find_by(avatax_uuid: uuid)
      end
    end

    def find_or_create_tax_rate(item, avatax_item)
      ::Spree::TaxRate.find_or_create_by!(
        name:               tax_rate_name,
        amount:             sum_rates_from_details(avatax_item),
        zone:               item.tax_zone&.reload,
        tax_category:       item.tax_category,
        show_rate_in_label: false,
        included_in_price:  item.included_in_price
      ) do |tax_rate|
        tax_rate.calculator = SpreeAvataxOfficial::Calculator::AvataxTransactionCalculator.new
      end
    end

    def tax_rate_name
      ENV.fetch('AVATAX_TAX_RATE_NAME', 'AvaTax Official Tax Rate')
    end

    def create_tax_adjustment(item, source, amount)
      item.adjustments.create!(
        source:   source,
        amount:   amount,
        included: item.included_in_price,
        label:    tax_adjustment_label(item, source.amount),
        order:    item.order
      )
    end

    def store_pre_tax_amount(item, tax_rate, tax_amount)
      pre_tax_amount = case item.class.name.demodulize
                       when 'LineItem' then item.discounted_amount
                       when 'Shipment' then item.discounted_cost
                       end

      pre_tax_amount -= tax_amount if tax_rate.included_in_price?

      item.update_column(:pre_tax_amount, pre_tax_amount)
    end

    def sum_rates_from_details(avatax_item)
      avatax_item['details']
        .sum { |detail_entry| detail_entry['rate'] }
        .round(6)
    end

    def build_error_message_from_response(avatax_response)
      return ::Spree.t('spree_avatax_official.create_tax_adjustments.tax_calculation_failed') unless error_present?(avatax_response)

      details = avatax_response.dig('error', 'details')
      return ::Spree.t('spree_avatax_official.create_tax_adjustments.tax_calculation_failed') if details.blank?

      details.map do |error_detail_entry|
        "#{error_detail_entry['number']} - #{error_detail_entry['message']} - #{error_detail_entry['description']}."
      end.join(' ')
    end

    def error_present?(avatax_response)
      avatax_response && avatax_response['error'].present?
    end
  end
end
