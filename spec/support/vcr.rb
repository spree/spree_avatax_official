require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir                    = 'spec/vcr'
  config.ignore_localhost                        = true
  config.default_cassette_options                = { record: ENV.fetch('VCR_RECORD_MODE', 'new_episodes').to_sym }

  config.configure_rspec_metadata!
  config.hook_into :webmock

  config.filter_sensitive_data('<AVATAX_TOKEN>') do |interaction|
    interaction.request.headers['Authorization']&.first
  end

  config.filter_sensitive_data('AVATAX_USERNAME') do |interaction|
    JSON(interaction.response.body)['authenticatedUserName'] rescue nil
  end
end
