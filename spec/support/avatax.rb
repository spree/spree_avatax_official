AvaTax.configure do |config|
  config.endpoint = 'https://sandbox-rest.avatax.com'
end

Spree::Config[:currency] = 'USD'
