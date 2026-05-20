module Spree
  module Admin
    class AvataxCustomerSettingsController < Spree::Admin::BaseController
      helper_method :object_url

      before_action :load_user
      before_action :load_entity_use_codes, only: %i[edit update]

      def edit; end

      def update
        if @user.update(permitted_resource_params)
          flash[:success] = flash_message_for(@user, :successfully_updated)
          redirect_to spree.admin_user_path(@user), status: :see_other
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def load_user
        @user = Spree.user_class.find_by_prefix_id!(params[:user_id])
        authorize! :update, @user

        @object = @user
        @resource = Spree::Admin::Resource.new(controller_path, controller_name, nil)
      end

      def object_url
        spree.admin_user_avatax_customer_settings_path(@user)
      end

      def load_entity_use_codes
        @entity_use_codes = SpreeAvataxOfficial::EntityUseCode.order(:code)
      end

      def permitted_resource_params
        params.require(:avatax_customer_setting).permit(:avatax_entity_use_code_id, :exemption_number, :vat_id)
      end
    end
  end
end
