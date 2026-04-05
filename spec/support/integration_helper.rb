module IntegrationHelper
  def avalara_integration
    Spree::Integrations::Avalara.first
  end

  def update_avalara_setting(key, value)
    integration = avalara_integration
    return unless integration

    integration.update!("preferred_#{key}" => value)
  end
end

RSpec.configure do |config|
  config.include IntegrationHelper
end
