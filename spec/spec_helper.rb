require 'dotenv'
Dotenv.load(File.expand_path('../.env', __dir__))

# Run Coverage report
require 'simplecov'
SimpleCov.start do
  add_filter 'spec/dummy'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Models', 'app/models'
  add_group 'Views', 'app/views'
  add_group 'Libraries', 'lib/spree'
end

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('dummy/config/environment.rb', __dir__)

require 'rspec/rails'
require 'ffaker'
require 'vcr'
require 'webmock/rspec'
require 'pry'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

# Requires factories and other useful helpers defined in spree_core.
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/caching'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/factories'
require 'spree/testing_support/url_helpers'

RSpec.configure do |config|
  # Infer an example group's spec type from the file location.
  config.infer_spec_type_from_file_location!

  # == URL Helpers
  #
  # Allows access to Spree's routes in specs:
  #
  # visit spree.admin_path
  # current_path.should eql(spree.products_path)
  config.include Spree::TestingSupport::UrlHelpers

  # == Requests support
  #
  # Adds convenient methods to request Spree's controllers
  # spree_get :index
  config.include Spree::TestingSupport::ControllerRequests, type: :controller

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec do |mocks|
    mocks.allow_message_expectations_on_nil = false
    mocks.verify_doubled_constant_names     = true
    mocks.verify_partial_doubles            = true
  end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]

  config.use_transactional_fixtures = true
  config.color                      = true
  config.raise_on_warning           = true
  config.order                      = 'random'
  config.default_formatter          = 'doc'
  config.fail_fast                  = ENV['FAIL_FAST'] || false

  config.before do
    Rails.cache.clear
    Spree::Current.reset

    Spree::Country.find_by(iso: 'US') || create(:country, name: 'United States', iso_name: 'UNITED STATES', iso: 'US', states_required: true)

    unless Spree::Store.exists?
      create(:store, default_currency: 'USD', default_country_id: Spree::Country.find_by(iso: 'US')&.id)
    end
  end

  config.before(:each, :avalara_integration) do
    store = Spree::Store.default
    Spree::Integrations::Avalara.find_by(store_id: store.id) || create(:avalara_integration, store: store) if store&.persisted?
  end

end
