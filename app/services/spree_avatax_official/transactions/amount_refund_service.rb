module SpreeAvataxOfficial
  module Transactions
    class AmountRefundService < SpreeAvataxOfficial::Base
      def call(order:, transaction_code:, amount:)
        response = send_request(order, transaction_code, amount)

        request_result(response, order) do
          create_transaction!(
            code:             response.body['code'],
            order:            order,
            transaction_type: SpreeAvataxOfficial::Transaction::RETURN_INVOICE
          )
        end
      end

      private

      def send_request(order, transaction_code, amount)
        model = SpreeAvataxOfficial::Transactions::AmountRefundPresenter.new(
          order:            order,
          amount:           amount,
          transaction_code: transaction_code
        ).to_json

        logger.info(model)

        client(order: order).refund_transaction(company_code(order), order.number, model)
      end
    end
  end
end
