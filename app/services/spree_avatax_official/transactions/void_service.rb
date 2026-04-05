module SpreeAvataxOfficial
  module Transactions
    class VoidService < SpreeAvataxOfficial::Base
      def call(order:, options: {})
        if order.avatax_sales_invoice_transaction.blank?
          return failure(::Spree.t('spree_avatax_official.void_service.missing_sales_invoice_transaction'))
        end

        response = send_request(order, options)

        request_result(response, order)
      end

      private

      def send_request(order, options)
        logger.info(options, order)

        client(order: order).void_transaction(
          company_code(order),
          order.number,
          { code: 'DocVoided' },
          options
        )
      end
    end
  end
end
