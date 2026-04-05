module SpreeAvataxOfficial
  module Spree
    module UserDecorator
      def self.prepended(base)
        base.belongs_to :avatax_entity_use_code, class_name: 'SpreeAvataxOfficial::EntityUseCode'
      end
    end
  end
end

Spree.user_class.prepend(::SpreeAvataxOfficial::Spree::UserDecorator) if Spree.user_class
