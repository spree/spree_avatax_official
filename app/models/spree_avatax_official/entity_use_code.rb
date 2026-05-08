module SpreeAvataxOfficial
  class EntityUseCode < ::Spree::Base
    self.whitelisted_ransackable_attributes = %w[code name description]

    with_options presence: true do
      validates :code, :name, uniqueness: true
    end
  end
end
