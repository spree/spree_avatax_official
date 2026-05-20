module SpreeAvataxOfficial
  class EntityUseCode < ::Spree.base_class
    self.whitelisted_ransackable_attributes = %w[code name description]

    validates :code, presence: true, uniqueness: { scope: spree_base_uniqueness_scope }
    validates :name, presence: true, uniqueness: { scope: spree_base_uniqueness_scope }
  end
end
