require 'spec_helper'

describe SpreeAvataxOfficial::AddressPresenter, :avalara_integration do
  describe '#to_json' do
    context 'when serializing ShipTo address' do
      subject { described_class.new(address: address, address_type: address_type) }

      let(:address) { create(:address) }
      let(:address_type) { 'ShipTo' }

      let(:result) do
        {
          address_type => {
            line1:      address.address1,
            line2:      address.address2,
            city:       address.city,
            region:     address.state.try(:abbr),
            country:    address.country.try(:iso),
            postalCode: address.zipcode
          }
        }
      end

      it 'serializes the object' do
        expect(subject.to_json).to eq result
      end
    end

    context 'when serializing ShipFrom address' do
      subject { described_class.new(address: address, address_type: address_type) }

      let(:address) { avalara_integration.preferred_ship_from_address }
      let(:address_type) { 'ShipFrom' }

      let(:result) do
        {
          address_type => {
            line1:      address[:line1],
            line2:      address[:line2],
            city:       address[:city],
            region:     address[:region],
            country:    address[:country],
            postalCode: address[:postalCode]
          }
        }
      end

      it 'serializes the object' do
        expect(subject.to_json).to eq result
      end
    end
  end
end
