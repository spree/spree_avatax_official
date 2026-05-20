FactoryBot.define do
  factory :avalara_integration, class: Spree::Integrations::Avalara do
    active { true }
    preferred_account_number { ENV.fetch('AVATAX_ACCOUNT_NUMBER', 'test_account') }
    preferred_license_key { ENV.fetch('AVATAX_LICENSE_KEY', 'test_license_key') }
    preferred_endpoint { ENV.fetch('AVATAX_ENDPOINT', 'https://sandbox-rest.avatax.com') }
    preferred_company_code { ENV.fetch('AVATAX_COMPANY_CODE', 'test1') }
    preferred_commit_transaction_enabled { true }
    preferred_address_validation_enabled { false }
    preferred_show_rate_in_label { false }
    preferred_ship_from_address do
      {
        line1: '822 Reed St',
        line2: '',
        city: 'Philadelphia',
        region: 'PA',
        country: 'USA',
        postalCode: '19147'
      }
    end
    store { Spree::Store.default || create(:store) }
  end
end
