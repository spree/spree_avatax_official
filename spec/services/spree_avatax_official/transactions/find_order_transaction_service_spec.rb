require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::FindOrderTransactionService, :avalara_integration do
  describe '#call' do
    subject                 { described_class.call(order: order) }

    let(:sales_transaction) { create(:spree_avatax_official_transaction, order: order, code: 'test123') }

    context 'with Spree::Order' do
      let(:order) { create(:order, number: 'test123') }

      context 'when order does have a SalesInvoice transaction' do
        it 'returns success' do
          sales_transaction

          expect(subject.success?).to eq true
        end
      end

      context 'when order does NOT have a SalesInvoice transaction', :vcr do
        context 'when transaction exists in avatax' do
          it 'returns success and creates a new SalesInvoice transaction' do
            expect(subject.success?).to eq true
            expect(SpreeAvataxOfficial::Transaction.count).to eq 1
          end
        end

        context 'when transaction does NOT exist in avatax' do
          it 'returns failure' do
            order.update(number: 'not-existing-number')

            expect(subject.success?).to eq false
          end
        end
      end
    end
  end
end
