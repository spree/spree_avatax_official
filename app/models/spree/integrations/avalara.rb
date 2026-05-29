module Spree
  module Integrations
    class Avalara < Spree::Integration
      SANDBOX_ENDPOINT = 'https://sandbox-rest.avatax.com'.freeze
      PRODUCTION_ENDPOINT = 'https://rest.avatax.com'.freeze

      preference :account_number, :string
      preference :license_key, :password
      preference :endpoint, :string, default: SANDBOX_ENDPOINT
      preference :company_code, :string

      preference :address_validation_enabled, :boolean, default: false
      preference :commit_transaction_enabled, :boolean, default: true
      preference :show_rate_in_label, :boolean, default: false

      validates :preferred_account_number, :preferred_license_key, :preferred_company_code, presence: true

      def self.integration_group
        'tax'
      end

      def self.icon_path
        'integration_icons/avalara-logo.png'
      end

      def can_connect?
        response = avatax_client.ping
        body     = response.respond_to?(:body) ? response.body : response

        return true if body.is_a?(Hash) && body['authenticated']

        @connection_error_message =
          if body.is_a?(Hash) && body.key?('authenticated')
            'Invalid credentials'
          elsif body.is_a?(Hash) && body['error'].is_a?(Hash)
            body['error']['message'].presence || 'Could not connect to AvaTax'
          else
            'Could not connect to AvaTax'
          end

        false
      rescue StandardError => e
        @connection_error_message = e.message
        false
      end

      def avatax_client
        AvaTax::Client.new(
          app_name:           SpreeAvataxOfficial::Base::APP_NAME,
          app_version:        SpreeAvataxOfficial::Base::APP_VERSION,
          connection_options: SpreeAvataxOfficial::Base::CONNECTION_OPTIONS,
          logger:             SpreeAvataxOfficial::Config.log,
          faraday_response:   true,
          endpoint:           preferred_endpoint,
          username:           preferred_account_number,
          password:           preferred_license_key
        )
      end
    end
  end
end
