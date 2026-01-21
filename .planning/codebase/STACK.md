# Technology Stack

**Analysis Date:** 2026-01-21

## Languages

**Primary:**
- Elixir 1.16+ - All backend application code, API layer, WebSocket handlers

**Secondary:**
- Rust (optional) - Native extensions via Rustler for cryptographic signing in `native/signer/`

## Runtime

**Environment:**
- Erlang/OTP - BEAM VM runtime for Elixir applications
- Supports distributed deployment

**Package Manager:**
- Mix (Elixir's package manager)
- Lockfile: `mix.lock` (generated)

## Frameworks

**Core:**
- Phoenix 2.1+ - Via `phoenix_pubsub` for real-time event broadcasting and PubSub (`Hyperliquid.PubSub`)
- Ecto 3.10+ - Optional database layer for persistence (when `enable_db: true`)

**Testing:**
- ExUnit - Built-in Elixir testing framework
- Bypass 2.1 - HTTP mocking for integration tests

**Build/Dev:**
- Credo 1.7 - Code linting and style analysis (dev/test only)
- ExDoc 0.31 - Documentation generation (dev only)
- Rustler 0.37.1 - Rust Native Interface for compiled extensions (optional, runtime: false)

## Key Dependencies

**Critical:**
- `httpoison` 1.7 - HTTP client for Info API requests and Exchange API calls
- `jason` 1.4 - JSON encoding/decoding for API requests and responses
- `gun` 2.0 - HTTP/WebSocket client library (lower-level transport)
- `mint_web_socket` 1.0.5 - WebSocket implementation using Mint for subscription endpoints

**Infrastructure:**
- `cachex` 4.1.1 - In-memory caching via ETS for asset metadata, mid prices, and exchange info
- `phoenix_pubsub` 2.1 - PubSub for broadcasting real-time events across processes
- `phoenix_ecto` 4.5 - Integration layer between Phoenix and Ecto (optional, only when `enable_db: true`)
- `ecto_sql` 3.10 - SQL adapter for Ecto (optional, only when `enable_db: true`)
- `postgrex` 0.0.0+ - PostgreSQL adapter (optional, only when `enable_db: true`)

## Configuration

**Environment:**
- Configuration via `config/config.exs` and environment-specific files:
  - `config/dev.exs` - Development overrides
  - `config/test.exs` - Test environment (testnet by default)
  - `config/dev.secret.exs` - Local secrets (not committed, see `.gitignore`)
  - Runtime config support via `config/runtime.exs` (pattern)

**Key Configs Required:**
- `config :hyperliquid, :chain` - Chain selection (`:mainnet` or `:testnet`, default: `:mainnet`)
- `config :hyperliquid, :private_key` - User's private key for signing transactions
- `config :hyperliquid, :enable_db` - Enable/disable Postgres persistence (default: `false`)
- `config :hyperliquid, :autostart_cache` - Auto-initialize cache on startup (default: `true`)
- `config :hyperliquid, :http_url` - Override default HTTP API URL
- `config :hyperliquid, :ws_url` - Override default WebSocket URL
- `config :hyperliquid, :named_rpcs` - Map of RPC endpoints for Ethereum calls

**Build:**
- `mix.exs` - Project manifest with dependencies, documentation config, aliases
- `.formatter.exs` - Elixir code formatter configuration (inputs: `config/lib/test/**/*.{ex,exs}`)

## Platform Requirements

**Development:**
- Elixir 1.16+ with Mix
- Optional: Rust toolchain (for building native extensions with Rustler)
- Optional: PostgreSQL 12+ (when `enable_db: true`)

**Production:**
- Erlang/OTP runtime
- Optional: PostgreSQL 12+ (when `enable_db: true`)
- Network access to Hyperliquid API:
  - Mainnet: `https://api.hyperliquid.xyz`
  - Testnet: `https://api.hyperliquid-testnet.xyz`
  - WebSocket: `wss://api.hyperliquid.xyz/ws` (mainnet) or `wss://api.hyperliquid-testnet.xyz/ws` (testnet)

---

*Stack analysis: 2026-01-21*
