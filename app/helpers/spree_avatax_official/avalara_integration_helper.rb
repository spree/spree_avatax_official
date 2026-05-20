module SpreeAvataxOfficial
  module AvalaraIntegrationHelper
    def avalara_ship_from(integration)
      (integration.preferred_ship_from_address || {}).with_indifferent_access
    end

    def avalara_endpoint_options
      [
        [::Spree.t('spree_avatax_official.endpoint_sandbox'),    ::Spree::Integrations::Avalara::SANDBOX_ENDPOINT],
        [::Spree.t('spree_avatax_official.endpoint_production'), ::Spree::Integrations::Avalara::PRODUCTION_ENDPOINT]
      ]
    end

    def avalara_selected_country(integration)
      integration.ship_from_country || ::Spree::Country.find_by(id: current_store.default_country_id)
    end
  end
end
