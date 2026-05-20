module Spree
  module PermittedAttributes
    @@user_attributes.push :avatax_entity_use_code_id, :exemption_number, :vat_id

    @@integration_attributes.push(
      preferred_ship_from_address: %i[
        line1 line2 city region country postalCode
        address1 address2 zipcode country_id state_id state_name
      ]
    )
  end
end