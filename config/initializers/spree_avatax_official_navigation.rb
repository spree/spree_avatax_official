Rails.application.config.after_initialize do
  Rails.application.config.spree.integrations << Spree::Integrations::Avalara

  settings_nav = Spree.admin.navigation.settings

  settings_nav.add :avalara_entity_use_codes,
                   label: 'spree_avatax_official.avalara_entity_use_code',
                   url: :admin_avalara_entity_use_codes_path,
                   icon: 'list-details',
                   position: 106,
                   active: -> { controller_name == 'avalara_entity_use_codes' }

  Spree.admin.tables.register(:avalara_entity_use_codes,
                              model_class: SpreeAvataxOfficial::EntityUseCode,
                              search_param: :code_cont)

  Spree.admin.tables.avalara_entity_use_codes.add :code,
                                                  label: :code,
                                                  type: :link,
                                                  sortable: true,
                                                  filterable: true,
                                                  default: true,
                                                  position: 10

  Spree.admin.tables.avalara_entity_use_codes.add :name,
                                                  label: :name,
                                                  type: :string,
                                                  sortable: true,
                                                  filterable: true,
                                                  default: true,
                                                  position: 20

  Spree.admin.tables.avalara_entity_use_codes.add :description,
                                                  label: :description,
                                                  type: :string,
                                                  sortable: false,
                                                  default: true,
                                                  position: 30

  # Surface the per-customer AvaTax settings drawer in the customer page-actions dropdown.
  Spree.admin.partials.body_start << 'spree/admin/shared/avatax_customer_settings_link'
end
