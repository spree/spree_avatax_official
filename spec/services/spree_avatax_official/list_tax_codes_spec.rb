require 'spec_helper'

describe SpreeAvataxOfficial::ListTaxCodes do
  subject(:result) { described_class.call(store: store, query: query) }

  let(:store) { Spree::Store.default }

  context 'with an active Avalara integration', :avalara_integration do
    context 'when the query matches Avalara tax codes' do
      let(:query) { 'clothing' }

      it 'returns the matching tax codes as TaxCodeData records' do
        VCR.use_cassette('spree_avatax_official/tax_codes/search_success') do
          expect(result).to be_success

          tax_codes = result.value
          expect(tax_codes.size).to eq(233)
          expect(tax_codes).to all(be_a(described_class::TaxCodeData))

          expect(tax_codes.first.code).to eq('PC020595')
          expect(tax_codes.first.name).to eq('Clothing And Related Products / Hydration packs')
        end
      end
    end

    context 'when the query only matches expired (inactive) tax codes' do
      # On Avalara, the OP01* family is entirely "Expired Tax Code - Do Not Use"
      # (isActive: false). The lookup must never surface these.
      let(:query) { 'OP01' }

      it 'excludes them by filtering on active tax codes only' do
        VCR.use_cassette('spree_avatax_official/tax_codes/excludes_expired') do
          expect(result).to be_success
          expect(result.value).to eq([])
        end
      end
    end

    context 'when the query is shorter than the minimum length' do
      let(:query) { 'a' }

      it 'returns an empty array without calling Avalara' do
        expect_any_instance_of(AvaTax::Client).not_to receive(:list_tax_codes)

        expect(result).to be_success
        expect(result.value).to eq([])
      end
    end

    context 'when Avalara returns an error' do
      let(:query) { 'clothing' }

      before do
        stub_request(:get, %r{sandbox-rest\.avatax\.com/api/v2/definitions/taxcodes}).
          to_return(
            status:  400,
            headers: { 'Content-Type' => 'application/json' },
            body:    { error: { code: 'AuthenticationException', message: 'Not authorized' } }.to_json
          )
      end

      it 'degrades gracefully to an empty array' do
        expect(result).to be_success
        expect(result.value).to eq([])
      end
    end
  end

  context 'without an Avalara integration configured' do
    let(:query) { 'clothing' }

    it 'returns an empty array' do
      expect(result).to be_success
      expect(result.value).to eq([])
    end
  end
end
