module SpreeAvataxOfficial
  class Seeder
    def seed!
      create_default_tax_category
      create_and_assign_shipping_tax_category
      create_entry_use_codes
    end

    private

    def create_default_tax_category
      ::Spree::TaxCategory.find_or_create_by!(name: 'Clothing')
                          .update!(tax_code: ::Spree::TaxCategory::DEFAULT_TAX_CODES['LineItem'])
    end

    def create_and_assign_shipping_tax_category
      shipping_tax_category = ::Spree::TaxCategory.find_or_create_by!(name: 'Shipping')
      shipping_tax_category.update!(tax_code: ::Spree::TaxCategory::DEFAULT_TAX_CODES['Shipment'])

      ::Spree::ShippingMethod.update_all(tax_category_id: shipping_tax_category.id)
    end

    def create_entry_use_codes
      use_codes.each do |key, val|
        SpreeAvataxOfficial::EntityUseCode.find_or_create_by!(code: key, name: val)
      end
    end

    def use_codes
      {
        'A': 'FEDERAL GOV',
        'B': 'STATE GOV',
        'C': 'TRIBAL GOVERNMENT',
        'D': 'FOREIGN DIPLOMAT',
        'E': 'CHARITABLE/EXEMPT ORG',
        'F': 'RELIGIOUS ORG',
        'G': 'RESALE',
        'H': 'AGRICULTURE',
        'I': 'INDUSTRIAL PROD/MANUFACTURERS',
        'J': 'DIRECT PAY',
        'K': 'DIRECT MAIL',
        'L': 'OTHER/CUSTOM',
        'N': 'EDUCATIONAL ORG',
        'P': 'COMMERCIAL AQUACULTURE',
        'Q': 'COMMERCIAL FISHERY',
        'R': 'NON-RESIDENT',
        'TAXABLE': 'NON-EXEMPT TAXABLE CUSTOMER'
      }
    end
  end
end
