require 'spec_helper'

describe SpreeAvataxOfficial::Transactions::PartialRefundPresenter, :avalara_integration do
  before { allow(SpreeAvataxOfficial::CreateTaxAdjustmentsService).to receive(:call).and_return(Spree::ServiceModule::Result.new(true, true)) }
  subject do
    described_class.new(
      order:            order,
      refund_items:     { line_item => [quantity, amount] },
      transaction_code: "#{order.number}-1"
    )
  end

  let(:result) do
    {
      type:                     'ReturnInvoice',
      companyCode:              order.avalara_integration&.preferred_company_code.presence || order.store.try(:avatax_company_code),
      reportingLocationCode:    order.avatax_reporting_location_code,
      referenceCode:            order.number,
      code:                     "#{order.number}-1",
      date:                     order.updated_at.strftime('%Y-%m-%d'),
      customerCode:             order.email,
      lines:                    [SpreeAvataxOfficial::ItemPresenter.new(item: line_item, custom_quantity: quantity, custom_amount: amount).to_json],
      commit:                   true,
      discount:                 0.0,
      entityUseCode:            order.try(:user).avatax_entity_use_code.try(:code),
      exemptionNo:              nil,
      businessIdentificationNo: nil,
      currencyCode:             order.currency,
      purchaseOrderNo:          order.number,
      taxOverride:              {
        reason:  'Refund',
        taxDate: order.completed_at.strftime('%Y-%m-%d'),
        type:    'TaxDate'
      }
    }
  end

  let(:order)     { create(:order_with_line_items) }
  let(:line_item) { order.line_items.first }
  let(:quantity)  { line_item.quantity - 1 }
  let(:amount)    { line_item.amount * 2 }

  it 'serializes the object' do
    order.update(completed_at: Time.current)

    expect(subject.to_json).to eq result
  end
end
