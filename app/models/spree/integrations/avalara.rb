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
      preference :ship_from_address, :hash, default: {}

      validates :preferred_account_number, :preferred_license_key, presence: true

      before_validation :normalize_ship_from_address_keys

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
          logger:             true,
          faraday_response:   true,
          endpoint:           preferred_endpoint,
          username:           preferred_account_number,
          password:           preferred_license_key
        )
      end

      # Reverse-lookups used by the admin form so the country/state selects
      # can preselect the right record from the stored ISO/abbr values.
      def ship_from_country
        @ship_from_country ||= begin
          iso = preferred_ship_from_address[:country]
          iso.present? ? ::Spree::Country.find_by(iso: iso) : nil
        end
      end

      def ship_from_state
        @ship_from_state ||= begin
          abbr    = preferred_ship_from_address[:region]
          country = ship_from_country

          ::Spree::State.find_by(country_id: country.id, abbr: abbr) if abbr.present? && country.present?
        end
      end

      def ship_from_state_name
        @ship_from_state_name ||= preferred_ship_from_address[:region] if ship_from_state.blank?
      end

      private

      # The admin form posts a Spree address attributes
      # (country_id / state_id / state_name / address1 / city / zipcode);
      # the stored shape mirrors Avalara's AddressLocationInfo
      # (country / region / line1 / line2 / city / postalCode). This
      # callback turns the former into the latter, and leaves an
      # already-stored hash alone.
      def normalize_ship_from_address_keys
        value = preferred_ship_from_address
        return unless value.is_a?(Hash)

        attributes = value.symbolize_keys

        if attributes.key?(:country_id) || attributes.key?(:state_id) || attributes.key?(:address1) || attributes.key?(:zipcode)
          self.preferred_ship_from_address = parse_ship_from_address(attributes)
        else
          self.preferred_ship_from_address = attributes
        end
      end

      def parse_ship_from_address(attributes)
        country = ::Spree::Country.find_by(id: attributes[:country_id]) if attributes[:country_id].present?
        state   = ::Spree::State.find_by(id: attributes[:state_id])     if attributes[:state_id].present?

        {
          line1:      attributes[:address1].presence,
          line2:      attributes[:address2].presence,
          city:       attributes[:city].presence,
          region:     state&.abbr.presence || attributes[:state_name].presence,
          country:    country&.iso,
          postalCode: attributes[:zipcode].presence
        }.compact
      end
    end
  end
end
