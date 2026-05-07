require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::CreateService, :avalara_integration do
  describe '#call' do
    context 'with correct parameters' do
      let(:order) { create(:order_with_line_items, line_items_count: 1, ship_address: create(:usa_address)) }

      context 'for SalesOrder and Avalara API successful response' do
        subject { described_class.call(order: order) }

        it 'returns positive result' do
          VCR.use_cassette('spree_avatax_official/transactions/create/sales_order_success') do
            result   = subject
            response = result.value

            expect(result.success?).to eq true
            expect(response['type']).to eq 'SalesOrder'
            expect(response['status']).to eq 'Temporary'
            expect(response['lines'].size).to eq 2
            expect(SpreeAvataxOfficial::Transaction.count).to eq 0
          end
        end
      end

      context 'for SalesInvoice and Avalara API successful response' do
        subject { described_class.call(order: order) }

        let(:order) { create(:order_with_line_items, line_items_count: 1, ship_address: create(:usa_address)) }

        it 'returns positive result' do
          VCR.use_cassette('spree_avatax_official/transactions/create/invoice_order_success') do
            result   = subject
            response = result.value

            expect(result.success?).to eq true
            expect(response['type']).to eq 'SalesOrder'
            expect(response['status']).to eq 'Temporary'
            expect(response['lines'].size).to eq 2
          end
        end

        context 'with complete order' do
          it 'creates transaction with Committed status' do
            VCR.use_cassette('spree_avatax_official/transactions/create/complete_order_success') do
              order.update(state: :complete, completed_at: Time.current)

              result   = subject
              response = result.value

              expect(result.success?).to eq true
              expect(response['type']).to eq 'SalesInvoice'
              expect(response['status']).to eq 'Committed'
              expect(SpreeAvataxOfficial::Transaction.count).to eq 1
            end
          end
        end
      end

      context 'and Avalara API timeout' do
        subject do
          described_class.call(
            order:   order,
            options: { '$include' => 'ForceTimeout' }
          )
        end

        let(:connection_options) { { request: { timeout: 120.0, open_timeout: 120.0 } } }

        before do
          allow_any_instance_of(AvaTax::Client).to receive(:connection_options).and_return(connection_options) # rubocop:disable RSpec/AnyInstance
        end

        it 'returns negative result' do
          VCR.use_cassette('spree_avatax_official/transactions/create/timeout') do
            result   = subject
            response = result.value

            expect(result.success?).to eq false
            expect(response['error']).to be_present
            expect(response['error']['code']).to eq 'TimeoutRequested'
          end
        end
      end

      # Faraday-level timeouts can't be recorded by VCR (the connection never
      # completes). Stub WebMock to raise the relevant error class directly —
      # the gem's `Avatax::RequestDecorator` rescue catches it and returns a
      # `mock_error_response` with `code: 'ConnectionError'`.
      context 'and Faraday read timeout' do
        subject { described_class.call(order: order) }

        before do
          stub_request(:post, %r{sandbox-rest\.avatax\.com/api/v2/transactions/create}).to_raise(Net::ReadTimeout)
        end

        it 'returns negative result' do
          result   = subject
          response = result.value

          expect(result.success?).to eq false
          expect(response['error']).to be_present
          expect(response['error']['code']).to eq 'ConnectionError'
          expect(response['error']['message'] =~ /Net::ReadTimeout/).to be_truthy
        end
      end

      context 'and Faraday open timeout' do
        subject { described_class.call(order: order) }

        before do
          stub_request(:post, %r{sandbox-rest\.avatax\.com/api/v2/transactions/create}).to_raise(Faraday::ConnectionFailed.new('Net::OpenTimeout'))
        end

        it 'returns negative result' do
          result   = subject
          response = result.value

          expect(result.success?).to eq false
          expect(response['error']).to be_present
          expect(response['error']['code']).to eq 'ConnectionError'
          expect(response['error']['message']).to eq 'Faraday::ConnectionFailed - Net::OpenTimeout'
        end
      end
    end

    context 'with incorrect parameters' do
      subject { described_class.call(order: order_without_line_items) }

      let(:order_without_line_items) { create(:order, ship_address: create(:usa_address)) }

      it 'returns negative result' do
        VCR.use_cassette('spree_avatax_official/transactions/create/failure') do
          result = subject

          expect(result.success?).to eq false
        end
      end
    end

    context 'Non US taxes' do
      subject { described_class.call(order: order) }

      let(:order)          { create(:avatax_order, line_items_count: 1) }
      let(:canada_address) { create(:canada_address) }
      let(:europe_address) { create(:europe_address) }
      let(:tax_summary)    { subject.value['summary'].first }

      let(:from_canada) do
        {
          line1:      '298 Pinetree',
          line2:      '',
          city:       'BEACONSFIELD',
          region:     'QC',
          country:    'CAN',
          postalCode: 'H9W 5E1'
        }
      end

      let(:from_usa) do
        {
          line1:      '822 Reed St',
          line2:      '',
          city:       'Philadelphia',
          region:     'PA',
          country:    'USA',
          postalCode: '19147'
        }
      end

      let(:from_europe) do
        {
          line1:      '10 Paternoster Sq',
          line2:      '',
          city:       'London',
          region:     '',
          country:    'GBR',
          postalCode: 'EC4M 7LS'
        }
      end

      context 'VAT' do
        context 'US to Europe sale' do
          it 'calculates VAT' do
            VCR.use_cassette('spree_avatax_official/transactions/create/vat/us_to_europe') do
              order.update(ship_address: europe_address)
              expect(tax_summary['taxName']).to eq 'GB VAT'
            end
          end
        end

        context 'Europe to Europe sale' do
          it 'calculates VAT' do
            VCR.use_cassette('spree_avatax_official/transactions/create/vat/europe_to_europe') do
              update_avalara_setting(:ship_from_address, from_europe)
              order.update(ship_address: europe_address)
              expect(tax_summary['taxName']).to eq 'GB VAT'
            end
          end
        end

        context 'Europe to US sale' do
          it 'calculates US tax' do
            VCR.use_cassette('spree_avatax_official/transactions/create/vat/europe_to_us') do
              update_avalara_setting(:ship_from_address, from_europe)
              expect(tax_summary['taxName']).to eq 'PA STATE TAX'
            end
          end
        end
      end

      context 'GST/TPS' do
        context 'US to Canada sale' do
          it 'calculates GST/TPS' do
            VCR.use_cassette('spree_avatax_official/transactions/create/gst/us_to_canada') do
              order.update(ship_address: canada_address)
              expect(tax_summary['taxName']).to eq 'CANADA GST/TPS'
            end
          end
        end

        context 'Canada to Canada sale' do
          it 'calculates GST/TPS' do
            VCR.use_cassette('spree_avatax_official/transactions/create/gst/canada_to_canada') do
              update_avalara_setting(:ship_from_address, from_canada)
              order.update(ship_address: canada_address)
              expect(tax_summary['taxName']).to eq 'CANADA GST/TPS'
            end
          end
        end

        context 'Canada to US sale' do
          it 'calculates US tax' do
            VCR.use_cassette('spree_avatax_official/transactions/create/gst/canada_to_us') do
              update_avalara_setting(:ship_from_address, from_canada)
              expect(tax_summary['taxName']).to eq 'PA STATE TAX'
            end
          end
        end
      end
    end
  end
end
