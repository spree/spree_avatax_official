module SpreeAvataxOfficial
  class Transaction < ::Spree.base_class
    SALES_ORDER               = 'SalesOrder'.freeze
    SALES_INVOICE             = 'SalesInvoice'.freeze
    RETURN_INVOICE            = 'ReturnInvoice'.freeze
    DEFAULT_ADJUSTMENT_REASON = 'Other'.freeze

    AVAILABLE_TRANSACTION_TYPES = [
      SALES_INVOICE,
      RETURN_INVOICE
    ].freeze

    belongs_to :order, class_name: 'Spree::Order'

    validates :code, presence: true, uniqueness: { scope: spree_base_uniqueness_scope }

    with_options presence: true do
      validates :order
      validates :transaction_type
    end

    validates :transaction_type, inclusion: { in: AVAILABLE_TRANSACTION_TYPES }

    scope :sales_invoices,  -> { with_kind(SALES_INVOICE) }
    scope :return_invoices, -> { with_kind(RETURN_INVOICE) }
    scope :with_kind,       ->(*s) { where(transaction_type: s) }
  end
end
