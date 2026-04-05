require 'spec_helper'

describe Spree::Admin::AvalaraEntityUseCodesController, type: :controller do
  stub_authorization!

  describe '#index' do
    let!(:use_code) { create(:avalara_entity_use_code) }

    it 'returns 200 and lists use codes' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:use_codes)).to include(use_code)
    end
  end

  describe '#new' do
    it 'returns 200' do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#create' do
    it 'creates a new entity use code' do
      expect {
        post :create, params: { entity_use_code: { code: 'A', name: 'Federal Gov', description: 'Test' } }
      }.to change(SpreeAvataxOfficial::EntityUseCode, :count).by(1)

      expect(response).to redirect_to(admin_avalara_entity_use_codes_path)
    end
  end

  describe '#edit' do
    let!(:use_code) { create(:avalara_entity_use_code) }

    it 'returns 200' do
      get :edit, params: { id: use_code.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#update' do
    let!(:use_code) { create(:avalara_entity_use_code) }

    it 'updates the entity use code' do
      put :update, params: { id: use_code.id, entity_use_code: { code: 'updated_code' } }
      expect(use_code.reload.code).to eq 'updated_code'
      expect(response).to redirect_to(admin_avalara_entity_use_codes_path)
    end
  end

  describe '#destroy' do
    let!(:use_code) { create(:avalara_entity_use_code) }

    it 'destroys the entity use code' do
      expect {
        delete :destroy, params: { id: use_code.id }
      }.to change(SpreeAvataxOfficial::EntityUseCode, :count).by(-1)

      expect(response).to redirect_to(admin_avalara_entity_use_codes_path)
    end
  end
end
