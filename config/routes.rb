Spree::Core::Engine.add_routes do
  namespace :admin do
    resources :avalara_entity_use_codes, except: :show
    resources :avalara_tax_codes, only: :index, defaults: { format: :json }

    resources :users, only: [] do
      resource :avatax_customer_settings, only: %i[edit update]
    end
  end
end
