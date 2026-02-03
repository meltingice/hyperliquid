# Configuration

## Minimal Setup

The only required configuration is a private key:

```elixir
# config/config.exs
config :hyperliquid,
  private_key: "YOUR_PRIVATE_KEY_HERE"
```

## All Options

```elixir
config :hyperliquid,
  # Chain selection (:mainnet or :testnet)
  chain: :mainnet,

  # API endpoint overrides (optional, defaults based on chain)
  http_url: "https://api.hyperliquid.xyz",
  ws_url: "wss://api.hyperliquid.xyz/ws",
  rpc_url: "https://api.hyperliquid.xyz/evm",

  # Authentication
  private_key: "YOUR_PRIVATE_KEY_HERE",

  # Feature flags
  enable_db: false,          # Postgres persistence
  enable_web: false,         # Web/Phoenix features
  autostart_cache: true,     # Auto-initialize cache on startup
  debug: false,              # Debug logging

  # Cache tuning
  cache_max_entries: 5000,
  cache_default_ttl: 300_000,   # 5 minutes
  cache_mids_ttl: 60_000,       # 1 minute
  cache_meta_ttl: 600_000,      # 10 minutes

  # Named RPC endpoints (for EVM JSON-RPC)
  named_rpcs: %{
    alchemy: "https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY",
    quicknode: "https://your-endpoint.quiknode.pro/YOUR_KEY"
  }
```

## Testnet

Switch to testnet by setting the chain:

```elixir
config :hyperliquid,
  chain: :testnet,
  private_key: "YOUR_TESTNET_KEY"
```

When using testnet with database persistence, the database name automatically gets a `_testnet` suffix.

## Database

Enable Postgres persistence:

```elixir
config :hyperliquid,
  enable_db: true

config :hyperliquid, Hyperliquid.Repo,
  database: "hyperliquid_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
```

## Environment Variables

For production, use environment variables for secrets:

```elixir
config :hyperliquid,
  private_key: System.get_env("HYPERLIQUID_PRIVATE_KEY")
```
