require 'spec_helper'

describe Spree::Admin::IntegrationsController, type: :controller do
  stub_authorization!

  let!(:integration) { create(:avalara_integration, active: true) }

  before do
    allow(controller).to receive(:current_store).and_return(integration.store)
    allow_any_instance_of(Spree::Integrations::Avalara).to receive(:can_connect?).and_return(true)
  end

  describe '#update' do
    it 'disables AvaTax when the toggle is unchecked' do
      put :update, params: { id: integration.prefixed_id, integration: { active: '0' } }

      expect(integration.reload.active).to be false
    end

    it 're-enables AvaTax when the toggle is checked' do
      integration.update!(active: false)

      put :update, params: { id: integration.prefixed_id, integration: { active: '1' } }

      expect(integration.reload.active).to be true
    end
  end
end
