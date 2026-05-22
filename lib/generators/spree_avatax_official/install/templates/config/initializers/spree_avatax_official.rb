Rails.application.config.after_initialize do
  # Global configuration (connection tuning and logging)
  # Per-store credentials and settings are configured via the Avalara integration
  # in the Spree admin panel under Settings > Integrations.
  SpreeAvataxOfficial::Config.log            = true
  SpreeAvataxOfficial::Config.log_to_stdout  = true
  SpreeAvataxOfficial::Config.max_retries    = 2
  SpreeAvataxOfficial::Config.open_timeout   = 2.0
  SpreeAvataxOfficial::Config.read_timeout   = 6.0

  # To log to a file instead of STDOUT, set `log_to_stdout = false` above and
  # uncomment the settings below. `log_file_name` is the file written under
  # `Rails.root/log/`, and `log_frequency` controls log rotation
  # ('daily', 'weekly', or 'monthly').

  # SpreeAvataxOfficial::Config.log_file_name = 'avatax.log'
  # SpreeAvataxOfficial::Config.log_frequency = 'weekly'
end
