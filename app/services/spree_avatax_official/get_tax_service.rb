module SpreeAvataxOfficial
  class GetTaxService < SpreeAvataxOfficial::Base
    def call(order:, options: {})
      response = send_request(order, options)

      return failure(response) if response.body['error'].present?

      success(taxCalculated: response.body['totalTaxCalculated'])
    end

    def send_request(order, options)
      create_transaction_model = SpreeAvataxOfficial::Transactions::CreatePresenter.new(
        order:            order,
        transaction_type: SpreeAvataxOfficial::Transaction::SALES_ORDER
      ).to_json

      client(order: order).create_transaction(create_transaction_model, options)
    end
  end
end
