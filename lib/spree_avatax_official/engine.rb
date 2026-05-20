require_relative 'configuration'

module SpreeAvataxOfficial
  class Engine < Rails::Engine
    require 'avatax'

    isolate_namespace SpreeAvataxOfficial
    engine_name 'spree_avatax_official'

    config.autoload_paths += %W[#{config.root}/lib]

    initializer 'spree_avatax_official.environment', before: :load_config_initializers do |_app|
      SpreeAvataxOfficial::Config = SpreeAvataxOfficial::Configuration.new
    end

    config.after_initialize do |app|
      app.config.spree.calculators.tax_rates << SpreeAvataxOfficial::Calculator::AvataxTransactionCalculator
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.eager_load ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
