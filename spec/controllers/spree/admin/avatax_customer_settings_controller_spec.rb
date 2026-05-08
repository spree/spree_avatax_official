require 'spec_helper'

describe Spree::Admin::AvataxCustomerSettingsController, type: :controller do
  stub_authorization!

  let(:user) { create(:user) }

  describe '#edit' do
    it 'renders the drawer form' do
      get :edit, params: { user_id: user.to_param }

      expect(response).to have_http_status(:ok)
      expect(assigns(:user)).to eq user
    end
  end

  describe '#update' do
    let(:entity_use_code) { create(:avalara_entity_use_code) }

    let(:valid_params) do
      {
        user_id: user.to_param,
        avatax_customer_setting: {
          avatax_entity_use_code_id: entity_use_code.id,
          exemption_number:          'CERT-12345',
          vat_id:                    'GB123456789'
        }
      }
    end

    it 'persists the avatax fields and redirects to the user' do
      patch :update, params: valid_params

      user.reload
      expect(user.avatax_entity_use_code_id).to eq entity_use_code.id
      expect(user.exemption_number).to eq 'CERT-12345'
      expect(user.vat_id).to eq 'GB123456789'
      expect(response).to redirect_to(spree.admin_user_path(user))
      expect(response).to have_http_status(:see_other)
    end

    it 'allows clearing the entity use code by submitting blank' do
      user.update!(avatax_entity_use_code_id: entity_use_code.id)

      patch :update, params: valid_params.deep_merge(avatax_customer_setting: { avatax_entity_use_code_id: '' })

      expect(user.reload.avatax_entity_use_code_id).to be_nil
    end

    it 'ignores parameters outside the allowlist' do
      patch :update, params: valid_params.deep_merge(avatax_customer_setting: { email: 'attacker@example.com' })

      user.reload
      expect(user.email).not_to eq 'attacker@example.com'
    end
  end
end
