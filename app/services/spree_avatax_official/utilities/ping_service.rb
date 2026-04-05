module SpreeAvataxOfficial
  module Utilities
    class PingService < SpreeAvataxOfficial::Base
      def call(store:)
        integration = store.integrations.active.find_by(type: 'Spree::Integrations::Avalara')
        return failure('Avalara integration is not configured') unless integration

        request_result(integration.avatax_client.ping)
      end
    end
  end
end
