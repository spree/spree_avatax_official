module TaxInclusiveHelper
  def enable_tax_inclusive_for_order(order)
    market = order.market
    if market
      market.update!(tax_inclusive: true)
    else
      country = order.tax_address&.country || Spree::Country.first
      market = order.store.markets.create!(
        name: 'Default',
        currency: order.store.default_currency || 'USD',
        default_locale: 'en',
        countries: [country],
        tax_inclusive: true
      )
      # Link the new market to the order so order.market.tax_inclusive returns
      # true when the AvaTax presenter builds the request payload.
      order.update!(market: market)
    end

    # Reload so any cached association (`order.market`) reflects the new value.
    order.reload

    market
  end
end

RSpec.configure do |config|
  config.include TaxInclusiveHelper
end
