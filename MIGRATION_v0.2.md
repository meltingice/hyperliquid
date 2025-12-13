# Migration Guide: v0.1.6 → v0.2.0

This guide covers the major changes in v0.2.0 and how to migrate from v0.1.6.

## Overview

Version 0.2.0 is a **major architectural upgrade** that introduces:

- **DSL-based API endpoints** - Macro-driven endpoint definitions with automatic request/response handling
- **130+ typed API endpoints** - 61 Info, 38 Exchange, 3 Explorer, 2 Stats, 26 Subscription endpoints
- **Optional database persistence** - Postgres integration via feature flags
- **WebSocket connection pooling** - Managed subscriptions with automatic reconnection
- **Ecto schema validation** - Type-safe responses for all endpoints
- **Cachex caching layer** - Application-wide cache for metadata and prices
- **Native Rust NIFs** - Optional high-performance signing (requires Rust compiler)

## Breaking Changes

### 1. Module Restructuring

**Old API (v0.1.6):**
```elixir
Hyperliquid.Api.Info.user_state(user)
Hyperliquid.Api.Exchange.market_order(...)
Hyperliquid.Streamer.subscribe(...)
```

**New API (v0.2.0):**
```elixir
Hyperliquid.Api.Info.UserState.request(user: user)
Hyperliquid.Api.Exchange.Order.request!(order_params)
Hyperliquid.Api.Subscription.AllMids.subscribe()
```

### 2. Configuration Changes

**Old config (v0.1.6):**
```elixir
config :hyperliquid,
  is_mainnet: true,
  ws_url: "wss://api.hyperliquid.xyz/ws",
  http_url: "https://api.hyperliquid.xyz",
  private_key: "YOUR_KEY_HERE"
```

**New config (v0.2.0):**
```elixir
config :hyperliquid,
  chain: :mainnet,  # or :testnet
  enable_db: false,  # set true for Postgres persistence
  enable_web: false,  # reserved for future Phoenix features
  autostart_cache: true,  # auto-populate cache on startup
  private_key: "YOUR_KEY_HERE"
```

### 3. Response Format

All endpoints now return validated Ecto structs instead of raw maps:

**Old (v0.1.6):**
```elixir
{:ok, %{"assetPositions" => [...]}}
```

**New (v0.2.0):**
```elixir
{:ok, %Hyperliquid.Api.Info.UserState{
  asset_positions: [
    %Hyperliquid.Api.Info.UserState.AssetPosition{...}
  ]
}}
```

### 4. WebSocket Subscriptions

**Old (v0.1.6):**
```elixir
Hyperliquid.Streamer.subscribe(:trades, "BTC")
```

**New (v0.2.0):**
```elixir
Hyperliquid.Api.Subscription.Trades.subscribe(coin: "BTC")
# Events are automatically validated and optionally stored
```

## Feature Flags

### Database Persistence (Optional)

To enable Postgres storage for API data:

```elixir
# config/dev.exs
config :hyperliquid,
  enable_db: true

config :hyperliquid, Hyperliquid.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "hyperliquid_dev",
  pool_size: 10
```

**Note:** Database features require additional dependencies:
```elixir
# mix.exs - these are marked as optional: true
{:phoenix_ecto, "~> 4.5"},
{:ecto_sql, "~> 3.10"},
{:postgrex, ">= 0.0.0"}
```

When `enable_db: false` (default):
- Only Cachex storage is available
- Hyperliquid.Repo won't start
- Storage.Writer will skip Postgres writes
- All WebSocket and HTTP functionality works normally

### Web Features (Future)

Reserved for future Phoenix/LiveView integration:

```elixir
config :hyperliquid,
  enable_web: true  # Not yet implemented in v0.2.0
```

## DSL-Based Endpoints

All endpoints now use a macro-based DSL that eliminates boilerplate:

### Info Endpoint Example

```elixir
defmodule Hyperliquid.Api.Info.UserState do
  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "clearinghouseState",
    params: [:user],
    rate_limit_cost: 20

  # Embedded Ecto schema for response validation
  embedded_schema do
    field :withdrawable, :string
    embeds_many :asset_positions, AssetPosition do
      field :coin, :string
      field :position_value, :string
      # ...
    end
  end

  def changeset(struct \\ %__MODULE__{}, attrs) do
    # Validation logic
  end
end

# Usage
{:ok, state} = Hyperliquid.Api.Info.UserState.request(user: "0x123...")
state.asset_positions  # List of typed structs
```

### Exchange Endpoint Example

```elixir
# All exchange endpoints automatically sign requests
Hyperliquid.Api.Exchange.Order.request!(
  orders: [%{coin: "BTC", is_buy: true, ...}],
  grouping: "na"
)
```

### Subscription Endpoint Example

```elixir
# Subscribe to live trades for BTC
{:ok, _pid} = Hyperliquid.Api.Subscription.Trades.subscribe(coin: "BTC")

# Events are automatically validated and stored (if configured)
# Access via Storage.Writer or database queries
```

## Cache System

The new Cache module provides application-wide metadata and price caching:

```elixir
# Auto-initialized on startup (if autostart_cache: true)
Hyperliquid.Cache.get_mid("BTC")  # => "50000.5"
Hyperliquid.Cache.asset_from_coin("BTC")  # => %{name: "Bitcoin", ...}

# Subscribe to live mid price updates
Hyperliquid.Cache.subscribe_to_mids()
```

## Storage Layer

When database is enabled, endpoints can persist data automatically:

```elixir
# Endpoint with storage configuration
use Hyperliquid.Api.SubscriptionEndpoint,
  storage: [
    postgres: [
      enabled: true,
      table: "trades",
      extract: :trades,  # Extract nested field
      on_conflict: {:replace, [:price, :size]},
      conflict_target: [:trade_id]
    ],
    cache: [
      enabled: true,
      ttl: :timer.minutes(5),
      key_pattern: "trades:{{coin}}"
    ]
  ]
```

## Migration Checklist

- [ ] Update `mix.exs` dependency version to `~> 0.2.0`
- [ ] Run `mix deps.get` and `mix deps.compile`
- [ ] Update config files (see Configuration Changes above)
- [ ] Update module paths (see Module Restructuring above)
- [ ] Handle new response format (Ecto structs vs maps)
- [ ] Optional: Enable database features with `enable_db: true`
- [ ] Optional: Run migrations if using database: `mix ecto.migrate`
- [ ] Test WebSocket subscriptions with new API
- [ ] Update any direct cache access to use `Hyperliquid.Cache`

## Compiling Native Extensions

The Rust NIF for signing is optional. To compile it:

```bash
# Requires Rust 1.91+
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update

# Then compile normally
mix compile
```

To skip NIF compilation:

```bash
SKIP_RUSTLER_COMPILE=true mix compile
```

Note: Without the compiled NIF, exchange endpoints that require signing will fail at runtime. The NIF is not required for Info or Subscription endpoints.

## Complete Endpoint List

### Info API (61 endpoints)
- Meta, UserState, UserFills, UserFees, UserFunding, UserHistoricalOrders
- OpenOrders, FrontendOpenOrders, AllMids, UserRateLimit, OrderStatus
- L2Book, CandleSnapshot, SpotMeta, SpotClearinghouseState
- And 46 more...

### Exchange API (38 endpoints)
- Order, Cancel, CancelByCloid, ModifyOrder, BatchModify
- UpdateLeverage, UpdateIsolatedMargin, UsdSend, SpotSend, Withdraw
- VaultTransfer, SetReferrer, ApproveAgent, ApproveBuilderFee
- And 24 more...

### Explorer API (3 endpoints)
- BlockDetails, UserDetails, TxDetails

### Stats API (2 endpoints)
- Leaderboard, Vaults

### Subscription API (26 endpoints)
- AllMids, Trades, L2Book, OrderUpdates, UserEvents, UserFills
- UserFundings, Candle, WebData2, WebData3, Notification
- And 15 more...

## Getting Help

- Check the source code: each endpoint module has detailed documentation
- Read CLAUDE.md for architecture overview
- See the test suite for usage examples
- File issues on GitHub: https://github.com/skedzior/hyperliquid

## Backwards Compatibility

Version 0.2.0 is **not backwards compatible** with 0.1.6 due to the major architectural changes. We recommend thorough testing in a development environment before upgrading production systems.
