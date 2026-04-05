require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::GetByCodeService, :avalara_integration do
  describe '#call' do
    subject { described_class.call(**params) }

    let(:order)               { create(:order) }
    let!(:return_transaction) { create(:spree_avatax_official_transaction, :return_invoice, order: order, code: 'test321') }
    let!(:sales_transaction)  { create(:spree_avatax_official_transaction, order: order, code: 'test123') }

    context 'with correct params' do
      context 'with default transaction type' do
        let(:params) { { order: order } }

        it 'returns success' do
          VCR.use_cassette('spree_avatax_official/transactions/get_by_code/order_without_type_success') do
            expect(subject.value['type']).to eq 'SalesInvoice'
          end
        end

        context 'without sales transaction', :vcr do
          let(:params) { { order: order } }

          before do
            order.update(number: 'R677767217')
            order.avatax_transactions.destroy_all
          end

          it 'returns success' do
            VCR.use_cassette('spree_avatax_official/transactions/get_by_code/order_with_number_success') do
              result = subject.value

              expect(result['code']).to eq order.number
              expect(result['type']).to eq 'SalesInvoice'
            end
          end
        end
      end

      context 'with custom transaction type' do
        let(:params) { { order: order, type: 'ReturnInvoice' } }

        it 'returns success' do
          VCR.use_cassette('spree_avatax_official/transactions/get_by_code/order_with_type_success') do
            expect(subject.value['type']).to eq 'ReturnInvoice'
          end
        end
      end

      context 'with custom transaction code' do
        let(:params) { { order: order, type: 'ReturnInvoice', code: 'custom123' } }

        it 'returns success' do
          VCR.use_cassette('spree_avatax_official/transactions/get_by_code/order_with_custom_code_success') do
            expect(subject.success?).to eq true
            expect(subject.value['code']).to eq 'custom123'
          end
        end
      end
    end

    context 'with incorrect params' do
      let(:params) { { order: order } }

      before { sales_transaction.update(code: 'testerror') }

      it 'returns error' do
        VCR.use_cassette('spree_avatax_official/transactions/get_by_code/error') do
          expect(subject.value['error']['code']).to eq 'EntityNotFoundError'
        end
      end
    end
  end
end
