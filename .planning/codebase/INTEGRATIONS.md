# External Integrations

**Analysis Date:** 2026-01-21

## APIs & External Services

**Hyperliquid DEX API:**
- **Info API** - Read-only queries for market data, user account info, metadata (no authentication required)
  - SDK/Client: `httpoison` 1.7
  - Transport: `Hyperliquid.Transport.Http`
  - HTTP Module: `Hyperliquid.Api.Info` (convenience functions)
  - Base URL configured via: `Hyperliquid.Config.api_base/0`
    - Mainnet: `https://api.hyperliquid.xyz`
    - Testnet: `https://api.hyperliquid-testnet.xyz`

- **Exchange API** - Write operations (orders, cancellations, transfers, etc.) with signature-based authentication
  - SDK/Client: `httpoison` 1.7
  - Transport: `Hyperliquid.Transport.Http`
  - HTTP Module: `Hyperliquid.Api.Exchange` (convenience functions)
  - Signing: Via Rustler NIF in `Hyperliquid.Signer` (native cryptographic signing)
  - Base URL: Same as Info API

- **WebSocket Subscriptions** - Real-time market data and user updates
  - SDK/Client: `mint_web_socket` 1.0.5 + `gun` 2.0
  - Transport: `Hyperliquid.Transport.WebSocket` (GenServer-based connection pool)
  - WebSocket URL: Configured via `Hyperliquid.Config.ws_url/0`
    - Mainnet: `wss://api.hyperliquid.xyz/ws`
    - Testnet: `wss://api.hyperliquid-testnet.xyz/ws`
  - Connection pooling via `Hyperliquid.WebSocket.Supervisor` (one connection per parameter variant)
  - Auto-reconnection with exponential backoff (1s to 30s)

**Stats API:**
- **Leaderboard & Vault Data** - Historical performance metrics
  - HTTP Module: `Hyperliquid.Api.Stats` (leaderboard, vaults)
  - Base URL: Configured via `Hyperliquid.Config.stats_base/0`
    - Mainnet: `https://stats-data.hyperliquid.xyz`
    - Testnet: `https://stats-data.hyperliquid-testnet.xyz`

**Explorer RPC API:**
- **Block and Transaction Data** - EVM block/tx details via JSON-RPC
  - HTTP Module: `Hyperliquid.Api.Explorer` (user_details, block_details, tx_details)
  - Client: `Hyperliquid.Rpc` modules for EVM calls
  - Base URLs:
    - Mainnet: `https://rpc.hyperliquid.xyz/evm` (HTTP) and `wss://rpc.hyperliquid.xyz/ws` (WebSocket)
    - Testnet: `https://rpc.hyperliquid-testnet.xyz/evm` (HTTP) and `wss://rpc.hyperliquid-testnet.xyz/ws` (WebSocket)
  - Named RPC endpoints support: Register custom RPC providers via `config :hyperliquid, :named_rpcs`

## Data Storage

**Databases:**
- **PostgreSQL** (optional, default disabled)
  - Connection: Via `Hyperliquid.Repo` (Ecto adapter)
  - ORM/Client: `ecto_sql` 3.10 + `postgrex` adapter
  - Enabled: Set `config :hyperliquid, enable_db: true` and add `phoenix_ecto`, `ecto_sql`, `postgrex` dependencies
  - Database name: Automatically suffixed with `_testnet` when `chain: :testnet`
  - Schema generation via `mix hyperliquid.gen.schemas` task
  - Storage writer: `Hyperliquid.Storage.Writer` persists endpoint responses to tables based on endpoint configuration

**In-Memory Cache:**
- **Cachex** (ETS-based)
  - Purpose: Asset metadata, exchange info, mid prices
  - Cache name: `:hyperliquid`
  - Auto-initialization: Via `Hyperliquid.Cache.init()` on app startup (configurable via `autostart_cache: true/false`)
  - Stores: Exchange metadata (perps/spot), asset indices, decimal precision, token info, current mid prices
  - Refresh: 5-minute periodic refresh interval via `Hyperliquid.Cache`

**File Storage:**
- Local filesystem only - No external file storage service used

**Caching:**
- Cachex (ETS) - Built-in, always available
- Optional Redis/distributed cache: Not configured
- WebSocket-driven live updates: Mid price updates via `Hyperliquid.Cache.subscribe_to_mids()`

## Authentication & Identity

**Auth Provider:**
- Custom ECDSA signature-based authentication (no third-party auth provider)
- Implementation approach:
  - Private key stored in config: `config :hyperliquid, :private_key`
  - Cryptographic signing via Rustler NIF (`Hyperliquid.Signer`):
    - `sign_exchange_action/5` - Sign orders, cancellations, transfers
    - `sign_l1_action/3` - Sign on-chain L1 actions
    - `sign_usd_send/5` - Sign USD sends
    - `sign_multi_sig_action_ex/6` - Sign multi-sig actions
    - `sign_typed_data/5` - Sign EIP-712 typed data
  - Nonce generation: `compute_connection_id/3` via Signer NIF
  - Request format: Include JSON action payload + signature in Exchange API POST body

## Monitoring & Observability

**Error Tracking:**
- None detected - No external error tracking service integration
- Local error handling via `Hyperliquid.Error` module
- Logger integration for warnings/errors

**Logs:**
- Elixir Logger (default)
- Approach: `require Logger` in modules, use `Logger.info/1`, `Logger.warning/1` for key events
- WebSocket reconnection, cache initialization, storage writes logged

## CI/CD & Deployment

**Hosting:**
- Not specified - SDK is a library (package on Hex.pm)
- Deployment target: Any Erlang/OTP-compatible runtime

**CI Pipeline:**
- None detected in codebase - No CI config files (GitHub Actions, etc.)
- Mix test framework available for testing

## Environment Configuration

**Required env vars:**
- `HL_PRIVATE_KEY` (alternative to config) - User's private key for signing
- `DATABASE_URL` (optional, when `enable_db: true`) - PostgreSQL connection string

**Secrets location:**
- Config-driven: `config :hyperliquid, :private_key` in `config/config.exs` or environment-specific files
- Secure practice: Store in `config/dev.secret.exs` (file template: `config/dev.secret.exs.example`) or runtime config
- `.gitignore` excludes `dev.secret.exs` to prevent secret leaks

## Webhooks & Callbacks

**Incoming:**
- None - This is a client SDK, not a server accepting webhooks

**Outgoing:**
- WebSocket subscriptions provide streaming data callbacks (not traditional webhooks)
  - Subscription format: Register callback function on `WebSocket.subscribe/3`
  - Example: `WebSocket.subscribe(pid, %{type: "webData2", user: "0x..."}, fn event -> ... end)`
- PubSub broadcasts: Via Phoenix PubSub, events published by `Hyperliquid.Storage.Writer` and subscription modules

## Bridge Contract Integration

**Hyperliquid Bridge:**
- Contract address (mainnet): `0x2df1c51e09aecf9cacb7bc98cb1742757f163df7` (default, configurable)
- Contract address (testnet): `0x1870dc7a474e045026f9ef053d5bb20a250cc084`
- Configuration: `config :hyperliquid, :hl_bridge_contract` (override in config/dev.secret.exs)
- Used for: Deposits via Exchange API endpoint (`c_deposit`)

---

*Integration audit: 2026-01-21*
