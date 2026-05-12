require 'spec_helper'

describe Spree::LineItem do
  describe '#avatax_number' do
    let(:line_item) { create(:line_item) }

    it 'returns line item id with avatax code' do
      expect(line_item.avatax_number).to eq "LI-#{line_item.avatax_uuid}"
    end
  end
end
