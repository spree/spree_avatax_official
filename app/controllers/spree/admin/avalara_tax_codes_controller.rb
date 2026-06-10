module Spree
  module Admin
    class AvalaraTaxCodesController < Spree::Admin::BaseController
      # Remote-search source for the tax category form's tax code picker.
      # Returns TomSelect options (`[{ id:, name: }]`) filtered by `params[:q]`.
      def index
        authorize! :manage, Spree::TaxCategory

        result = SpreeAvataxOfficial::ListTaxCodes.call(store: current_store, query: params[:q])
        tax_codes = result.value.map do |tax_code|
          {
            id: tax_code.code,
            name: [tax_code.code, tax_code.name].compact_blank.join(' — ')
          }
        end

        render json: tax_codes
      end
    end
  end
end
