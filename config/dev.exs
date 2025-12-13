import Config

# Development configuration for Hyperliquid

# Uncomment to enable database persistence
# config :hyperliquid,
#   enable_db: true

# Database configuration (only used when enable_db: true)
# config :hyperliquid, Hyperliquid.Repo,
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost",
#   database: "hyperliquid_dev",
#   stacktrace: true,
#   show_sensitive_data_on_connection_error: true,
#   pool_size: 10

# Optional: Import secrets file (create config/dev.secret.exs for your private key)
if File.exists?("config/dev.secret.exs") do
  import_config "dev.secret.exs"
end
