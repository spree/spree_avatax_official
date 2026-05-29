module SpreeAvataxOfficial
  module AvalaraIntegrationHelper
    def avalara_endpoint_options
      [
        [::Spree.t('spree_avatax_official.endpoint_sandbox'),    ::Spree::Integrations::Avalara::SANDBOX_ENDPOINT],
        [::Spree.t('spree_avatax_official.endpoint_production'), ::Spree::Integrations::Avalara::PRODUCTION_ENDPOINT]
      ]
    end
  end
end
