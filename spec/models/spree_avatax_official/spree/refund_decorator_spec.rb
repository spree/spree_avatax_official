require 'spec_helper'

describe SpreeAvataxOfficial::Spree::RefundDecorator do
  describe '#create', :avalara_integration do
    let(:refund) { create(:refund, amount: 10) }

    context 'commit transaction enabled' do
      before { update_avalara_setting(:commit_transaction_enabled, true) }

      it 'calls refund service' do
        expect(SpreeAvataxOfficial::Transactions::RefundService).to receive(:call)

        refund
      end
    end

    context 'commit transaction disabled' do
      before { update_avalara_setting(:commit_transaction_enabled, false) }
      after { update_avalara_setting(:commit_transaction_enabled, true) }

      it 'doesnt call refund service' do
        expect(SpreeAvataxOfficial::Transactions::RefundService).to_not receive(:call)

        refund
      end
    end
  end
end
