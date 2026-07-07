require 'spec_helper'

describe Spree::Admin::AvalaraTaxCodesController, type: :controller do
  stub_authorization!

  describe '#index', :avalara_integration do
    it 'returns the matching tax codes as JSON' do
      VCR.use_cassette('spree_avatax_official/tax_codes/search_success') do
        get :index, params: { q: 'clothing' }, format: :json

        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)
        expect(body).to be_an(Array)
        expect(body.first).to include('id', 'name')
      end
    end

    it 'returns an empty array for a blank query' do
      get :index, params: { q: '' }, format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end
end
