require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::AmountRefundPresenter, :avalara_integration do
  before { allow(SpreeAvataxOfficial::CreateTaxAdjustmentsService).to receive(:call).and_return(Spree::ServiceModule::Result.new(true, true)) }

  subject do
    described_class.new(
      order:            order,
      amount:           amount,
      transaction_code: "#{order.number}-1"
    )
  end

  let(:order)  { create(:order_with_line_items) }
  let(:amount) { 27.45 }

  before { order.update(completed_at: Time.current) }

  describe '#to_json' do
    it 'sends a ReturnInvoice with the refund amount as a tax-inclusive line' do
      payload = subject.to_json
      line    = payload[:lines].first

      expect(payload[:type]).to eq 'ReturnInvoice'
      expect(payload[:code]).to eq "#{order.number}-1"
      expect(payload).not_to have_key(:taxOverride)

      expect(payload[:lines].size).to eq 1
      expect(line[:number]).to start_with('REFUND-')
      expect(line[:quantity]).to eq 1
      expect(line[:amount]).to eq(-amount.to_f)
      expect(line[:taxIncluded]).to eq true
      expect(line).not_to have_key(:taxOverride)
    end
  end
end
