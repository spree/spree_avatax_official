module SpreeAvataxOfficial
  module Address
    class Validate < SpreeAvataxOfficial::Base
      # Avalara's address validation API only supports US and Canadian addresses.
      SUPPORTED_COUNTRIES = %w[US CA].freeze

      def call(address:, order:)
        return success(nil) if address.nil? || !supported_country?(address)

        response = send_request(address, order)

        return failure(response) if errors?(response)

        success(response)
      end

      private

      def supported_country?(address)
        SUPPORTED_COUNTRIES.include?(address.country&.iso)
      end

      def errors?(response)
        response.body['messages'] || response.body['error']
      end

      def send_request(address, order)
        ship_to_address_model = SpreeAvataxOfficial::ShipToAddressPresenter.new(
          address: address
        ).to_json

        client(order: order).resolve_address(ship_to_address_model)
      end
    end
  end
end
