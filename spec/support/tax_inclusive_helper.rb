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
    end
    market
  end
end

RSpec.configure do |config|
  config.include TaxInclusiveHelper
end
