require 'factory_bot'

FACTORY_BOT_CLASS = defined?(FactoryGirl) ? FactoryGirl : FactoryBot

FACTORY_BOT_CLASS.find_definitions

Dir[File.join(File.dirname(__FILE__), '../../lib/spree_avatax_official/testing_support/factories/**/*.rb')].each do |f|
  load File.expand_path(f)
end

RSpec.configure do |config|
  config.include FACTORY_BOT_CLASS::Syntax::Methods
end
