module Spree
  module Admin
    module UsersControllerDecorator
      def self.prepended(base)
        base.before_action :load_use_codes, only: :avalara_information
      end

      def avalara_information
        if request.put? && @user.update(user_params)
          flash.now[:success] = Spree.t(:account_updated)
        end

        render :avalara_information
      end

      private

      def load_use_codes
        return if request.put?

        @use_codes = SpreeAvataxOfficial::EntityUseCode.all.map { |use_code| ["#{use_code.code} - #{use_code.name}", use_code.id] }
      end
    end
  end
end

::Spree::Admin::UsersController.prepend(Spree::Admin::UsersControllerDecorator)
