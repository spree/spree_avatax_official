Rails.application.config.after_initialize do
  Rails.application.config.spree.integrations << Spree::Integrations::Avalara

  settings_nav = Spree.admin.navigation.settings

  settings_nav.add :avalara_entity_use_codes,
                   label: 'spree_avatax_official.avalara_entity_use_code',
                   url: :admin_avalara_entity_use_codes_path,
                   icon: 'list-details',
                   position: 106,
                   active: -> { controller_name == 'avalara_entity_use_codes' }
end
