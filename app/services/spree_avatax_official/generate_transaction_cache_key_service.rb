module SpreeAvataxOfficial
  class GenerateTransactionCacheKeyService < SpreeAvataxOfficial::Base
    def call(order:)
      reloaded_order = order.class.includes(
        :line_items,
        :adjustments,
        :shipments               => :stock_location,
        order.tax_address_symbol => %i[state country]
      ).find(order.id)

      success(transaction_cache_key(reloaded_order))
    end

    private

    def transaction_cache_key(order)
      transaction_cache_key = [
        order_cache_key(order),
        tax_address_cache_key(order.tax_address),
        line_items_cache_key(order),
        shipments_cache_key(order.shipments),
        avalara_integration_cache_key(order),
        market_cache_key(order)
      ].join('-')

      # Cache key length has to be compressed as max_length is 250:
      # https://github.com/memcached/memcached/blob/master/memcached.h#L36
      "AvaTax-transaction-#{Digest::MD5.hexdigest(transaction_cache_key)}"
    end

    def order_cache_key(order)
      [
        order.number,
        order.avatax_discount_amount
      ].join('-')
    end

    def tax_address_cache_key(tax_address)
      [
        tax_address.address1,
        tax_address.address2,
        tax_address.city,
        tax_address.state.try(:abbr),
        tax_address.country.try(:iso),
        tax_address.zipcode
      ].join('-')
    end

    def line_items_cache_key(order) # rubocop:disable Metrics/MethodLength
      order.line_items.map do |line_item|
        [
          line_item.avatax_uuid,
          line_item.quantity,
          line_item.variant_id,
          line_item.price,
          line_item.amount,
          line_item.discounted_amount,
          order.line_items_discounted_in_avatax?,
          line_item.avatax_tax_code
        ].join('-')
      end.join('-')
    end

    def shipments_cache_key(shipments)
      shipments.map do |shipment|
        [
          shipment.avatax_uuid,
          shipment.discounted_cost,
          shipment.avatax_tax_code,
          stock_location_cache_key(shipment.stock_location)
        ].join('-')
      end.join('-')
    end

    def stock_location_cache_key(stock_location)
      [
        stock_location.address1,
        stock_location.address2,
        stock_location.city,
        stock_location.state.try(:abbr),
        stock_location.country.try(:iso)
      ].join('-')
    end

    def avalara_integration_cache_key(order)
      integration = order.avalara_integration

      [
        integration&.id,
        integration&.updated_at&.utc&.to_f,
        company_code(order)
      ].join('-')
    end

    def market_cache_key(order)
      market = order.market

      [
        market&.id,
        market&.tax_inclusive
      ].join('-')
    end
  end
end
