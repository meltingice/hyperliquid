import Config

# Main Hyperliquid configuration
config :hyperliquid,
  # Chain selection (:mainnet or :testnet)
  chain: :mainnet,

  # Optional feature flags (default: false)
  enable_db: false,
  enable_web: false,

  # Cache auto-initialization (default: true)
  autostart_cache: true,

  # Private key for signing transactions (override in dev.secret.exs or runtime.exs)
  private_key: "YOUR_KEY_HERE"

# Import environment-specific config
import_config "#{Mix.env()}.exs"
