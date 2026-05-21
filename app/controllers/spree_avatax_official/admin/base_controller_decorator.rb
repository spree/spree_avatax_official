module SpreeAvataxOfficial
  module Admin
    module BaseControllerDecorator
      def self.prepended(base)
        base.helper SpreeAvataxOfficial::AvalaraIntegrationHelper
      end
    end
  end
end

::Spree::Admin::BaseController.prepend(::SpreeAvataxOfficial::Admin::BaseControllerDecorator) if defined?(::Spree::Admin::BaseController)
