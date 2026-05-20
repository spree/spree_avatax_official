module SpreeAvataxOfficial
  module Transactions
    class GetByCodeService < SpreeAvataxOfficial::Base
      def call(order:, type: 'SalesInvoice', code: nil)
        code ||= transaction_code(order, type)

        return failure(::Spree.t('spree_avatax_official.get_by_code_service.missing_code')) if code.nil?

        request_result(get_by_code(code, order), order)
      end

      private

      def get_by_code(code, order)
        logger.info(code)

        client(order: order).get_transaction_by_code(
          company_code(order),
          code
        )
      end

      def transaction_code(order, type)
        transaction = order
                      .avatax_transactions
                      .find_by(transaction_type: type)

        transaction.try(:code) || order.number
      end
    end
  end
end
