module Spree
  module Admin
    class AvalaraEntityUseCodesController < ResourceController
      include Spree::Admin::SettingsConcern

      private

      def model_class
        SpreeAvataxOfficial::EntityUseCode
      end

      def permitted_resource_params
        params.require(:avalara_entity_use_code).permit(:code, :name, :description)
      end

      def collection_url(options = {})
        spree.admin_avalara_entity_use_codes_url(options)
      end

      def new_object_url(options = {})
        spree.new_admin_avalara_entity_use_code_url(options)
      end
    end
  end
end
