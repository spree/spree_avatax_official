require 'spec_helper'

RSpec.describe Spree::Integrations::Avalara do
  describe 'validations' do
    it 'requires preferred_account_number' do
      integration = build(:avalara_integration, preferred_account_number: nil)
      expect(integration).not_to be_valid
      expect(integration.errors[:preferred_account_number]).to include(/can't be blank/)
    end

    it 'requires preferred_license_key' do
      integration = build(:avalara_integration, preferred_license_key: nil)
      expect(integration).not_to be_valid
      expect(integration.errors[:preferred_license_key]).to include(/can't be blank/)
    end
  end

  describe '#preferred_ship_from_address=' do
    let(:integration) { build(:avalara_integration) }

    context 'with a hash already in the stored shape' do
      let(:stored_shape) do
        {
          'line1'      => '1 Test St',
          'line2'      => 'Suite 200',
          'city'       => 'Philadelphia',
          'region'     => 'PA',
          'country'    => 'US',
          'postalCode' => '19147'
        }
      end

      before do
        integration.preferred_ship_from_address = stored_shape
        integration.valid?
      end

      it 're-symbolizes every key' do
        expect(integration.preferred_ship_from_address.keys).to match_array(
          %i[line1 line2 city region country postalCode]
        )
      end

      it 'preserves every value verbatim under its symbol key' do
        expect(integration.preferred_ship_from_address).to eq(
          line1:      '1 Test St',
          line2:      'Suite 200',
          city:       'Philadelphia',
          region:     'PA',
          country:    'US',
          postalCode: '19147'
        )
      end
    end

    context 'with a Spree-address-shaped form payload (country_id + state_id)' do
      let(:country) { Spree::Country.find_by(iso: 'US') }
      let(:state)   { Spree::State.find_or_create_by!(country: country, abbr: 'PA', name: 'Pennsylvania') }

      before do
        integration.preferred_ship_from_address = {
          'address1'   => '822 Reed St',
          'address2'   => 'Suite 1',
          'city'       => 'Philadelphia',
          'zipcode'    => '19147',
          'country_id' => country.id.to_s,
          'state_id'   => state.id.to_s,
          'state_name' => ''
        }
        integration.valid?
      end

      it 'normalizes to the stored shape with ISO country and abbr region' do
        expect(integration.preferred_ship_from_address).to eq(
          line1:      '822 Reed St',
          line2:      'Suite 1',
          city:       'Philadelphia',
          region:     'PA',
          country:    'US',
          postalCode: '19147'
        )
      end
    end

    context "with a country whose states aren't in the DB (state_name fallback)" do
      let(:country) do
        Spree::Country.find_or_create_by!(iso: 'GB') do |c|
          c.name = 'United Kingdom'
          c.iso_name = 'UNITED KINGDOM'
          c.iso3 = 'GBR'
        end
      end

      before do
        integration.preferred_ship_from_address = {
          'address1'   => '10 Downing Street',
          'city'       => 'London',
          'zipcode'    => 'SW1A 2AA',
          'country_id' => country.id.to_s,
          'state_id'   => '',
          'state_name' => 'Greater London'
        }
        integration.valid?
      end

      it 'falls back to state_name for the region' do
        expect(integration.preferred_ship_from_address).to eq(
          line1:      '10 Downing Street',
          city:       'London',
          region:     'Greater London',
          country:    'GB',
          postalCode: 'SW1A 2AA'
        )
      end
    end
  end

  describe '#ship_from_country' do
    let(:integration) { build(:avalara_integration) }
    let(:country)     { Spree::Country.find_by(iso: 'US') }

    it 'resolves the country record from the stored ISO' do
      integration.preferred_ship_from_address = { country: 'US' }

      expect(integration.ship_from_country).to eq(country)
    end

    it 'returns nil when the stored ISO does not match any country' do
      integration.preferred_ship_from_address = { country: 'ZZ' }

      expect(integration.ship_from_country).to be_nil
    end

    it 'returns nil when no country is stored' do
      integration.preferred_ship_from_address = {}

      expect(integration.ship_from_country).to be_nil
    end
  end

  describe '#ship_from_state' do
    let(:integration) { build(:avalara_integration) }
    let(:country)     { Spree::Country.find_by(iso: 'US') }
    let(:state)       { Spree::State.find_or_create_by!(country: country, abbr: 'PA', name: 'Pennsylvania') }

    it 'resolves the state record from the stored abbr scoped to the country' do
      state # ensure persisted
      integration.preferred_ship_from_address = { country: 'US', region: 'PA' }

      expect(integration.ship_from_state).to eq(state)
    end

    it 'returns nil when the stored region does not match any state' do
      integration.preferred_ship_from_address = { country: 'US', region: 'Greater London' }

      expect(integration.ship_from_state).to be_nil
    end

    it 'returns nil when no country is stored' do
      integration.preferred_ship_from_address = { region: 'PA' }

      expect(integration.ship_from_state).to be_nil
    end
  end

  describe '#ship_from_state_name' do
    let(:integration) { build(:avalara_integration) }
    let(:country)     { Spree::Country.find_by(iso: 'US') }
    let(:state)       { Spree::State.find_or_create_by!(country: country, abbr: 'PA', name: 'Pennsylvania') }

    it 'returns nil when a matching state record exists' do
      state # ensure persisted
      integration.preferred_ship_from_address = { country: 'US', region: 'PA' }

      expect(integration.ship_from_state_name).to be_nil
    end

    it 'returns the stored region when no matching state record exists' do
      integration.preferred_ship_from_address = { country: 'US', region: 'Greater London' }

      expect(integration.ship_from_state_name).to eq('Greater London')
    end
  end

  describe '#can_connect?' do
    subject(:integration) { build(:avalara_integration) }

    context 'with valid sandbox credentials', vcr: { cassette_name: 'spree/integrations/avalara/can_connect/authenticated' } do
      it 'returns true and leaves connection_error_message blank' do
        expect(integration.can_connect?).to eq(true)
        expect(integration.connection_error_message).to be_nil
      end
    end

    context 'with invalid credentials', vcr: { cassette_name: 'spree/integrations/avalara/can_connect/unauthenticated' } do
      subject(:integration) do
        build(:avalara_integration,
              preferred_account_number: '0000000000',
              preferred_license_key:    'invalid_license_key')
      end

      it 'returns false and reports invalid credentials' do
        expect(integration.can_connect?).to eq(false)
        expect(integration.connection_error_message).to eq('Invalid credentials')
      end
    end


    context 'when the AvaTax host is unreachable' do
      before do
        stub_request(:get, %r{sandbox-rest\.avatax\.com/api/v2/utilities/ping})
          .to_raise(Faraday::ConnectionFailed.new('connection refused'))
      end

      it 'returns false and surfaces the underlying error message' do
        expect(integration.can_connect?).to eq(false)
        expect(integration.connection_error_message).to include('connection refused')
      end
    end

    context 'when AvaTax returns an unexpected non-JSON body' do
      before do
        stub_request(:get, %r{sandbox-rest\.avatax\.com/api/v2/utilities/ping}).to_return(
          status: 502,
          headers: { 'Content-Type' => 'text/html' },
          body: '<html>Bad Gateway</html>'
        )
      end

      it 'returns false and falls back to the generic message' do
        expect(integration.can_connect?).to eq(false)
        expect(integration.connection_error_message).to eq('Could not connect to AvaTax')
      end
    end
  end
end
