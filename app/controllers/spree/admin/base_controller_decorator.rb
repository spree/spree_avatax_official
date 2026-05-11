module SpreeAvataxOfficial
  module Spree
    module Admin
      module BaseControllerDecorator
        def self.prepended(base)
          base.helper SpreeAvataxOfficial::AvalaraIntegrationHelper
        end
      end
    end
  end
end

::Spree::Admin::BaseController.prepend ::SpreeAvataxOfficial::Spree::Admin::BaseControllerDecorator
