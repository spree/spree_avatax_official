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
  let(:amount) { order.total / 4 }

  before { order.update(completed_at: Time.current) }

  describe '#to_json' do
    it 'returns a RefundTransactionModel with refundType Percentage' do
      payload = subject.to_json

      expect(payload).to eq(
        refundTransactionCode: "#{order.number}-1",
        referenceCode:         order.number,
        refundDate:            Time.current.strftime('%Y-%m-%d'),
        refundType:            'Percentage',
        refundPercentage:      25.0
      )
    end

    it 'computes refundPercentage as (amount / order.total) * 100' do
      expect(subject.to_json[:refundPercentage]).to eq 25.0
    end

    context 'when the refund amount does not divide cleanly into the order total' do
      let(:amount) { order.total / 3 }

      it 'rounds refundPercentage to 6 decimal places' do
        expect(subject.to_json[:refundPercentage]).to eq 33.333333
      end
    end
  end
end
