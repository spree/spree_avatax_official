Rails.application.config.after_initialize do
  # Global configuration (connection tuning and logging)
  # Per-store credentials and settings are configured via the Avalara integration
  # in the Spree admin panel under Settings > Integrations.
  SpreeAvataxOfficial::Config.log            = true
  SpreeAvataxOfficial::Config.log_to_stdout  = false
  SpreeAvataxOfficial::Config.log_file_name  = 'avatax.log'
  SpreeAvataxOfficial::Config.log_frequency  = 'weekly'
  SpreeAvataxOfficial::Config.max_retries    = 2
  SpreeAvataxOfficial::Config.open_timeout   = 2.0
  SpreeAvataxOfficial::Config.read_timeout   = 6.0
end
