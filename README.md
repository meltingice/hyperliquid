# Hyperliquid

[![Hex.pm](https://img.shields.io/hexpm/v/hyperliquid.svg)](https://hex.pm/packages/hyperliquid)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Elixir SDK for the Hyperliquid decentralized exchange with DSL-based API endpoints, WebSocket subscriptions, and optional Postgres/Phoenix integration.

## Overview

Hyperliquid provides a comprehensive, type-safe interface to the Hyperliquid DEX. The v0.2.0 release introduces a modern DSL-based architecture that eliminates boilerplate while providing response validation, automatic caching, and optional database persistence.

## Features

- **DSL-based endpoint definitions** - Clean, declarative API with automatic function generation
- **125+ typed endpoints** - 61 Info endpoints, 38 Exchange endpoints, 26 WebSocket subscriptions
- **Ecto schema validation** - Built-in response validation and type safety
- **WebSocket connection pooling** - Efficient connection management with automatic reconnection
- **Cachex-based caching** - Fast in-memory asset metadata and mid price lookups
- **Optional Postgres persistence** - Config-driven database storage for API data
- **Testnet/mainnet support** - Easy chain switching with automatic database separation
- **Phoenix PubSub integration** - Real-time event broadcasting

## Installation

Add `hyperliquid` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hyperliquid, "~> 0.2.0"}
  ]
end
```

## Configuration

### Basic Configuration (No Database)

The minimal configuration requires only your private key:

```elixir
# config/config.exs
config :hyperliquid,
  private_key: "YOUR_PRIVATE_KEY_HERE"
```

### With Database Persistence

Enable database features by setting `enable_db: true` and adding the required dependencies:

```elixir
# mix.exs
defp deps do
  [
    {:hyperliquid, "~> 0.2.0"},
    # Required when enable_db: true
    {:phoenix_ecto, "~> 4.5"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, ">= 0.0.0"}
  ]
end
```

```elixir
# config/config.exs
config :hyperliquid,
  private_key: "YOUR_PRIVATE_KEY_HERE",
  enable_db: true

# Configure the Repo
config :hyperliquid, Hyperliquid.Repo,
  database: "hyperliquid_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
```

### Testnet Configuration

Switch to testnet and optionally disable automatic cache initialization:

```elixir
config :hyperliquid,
  chain: :testnet,
  private_key: "YOUR_TESTNET_KEY",
  autostart_cache: true  # Set to false to manually initialize cache
```

The database name automatically gets a `_testnet` suffix when using testnet.

### Advanced Configuration

```elixir
config :hyperliquid,
  # Chain selection
  chain: :mainnet,  # or :testnet

  # API endpoints (optional - defaults based on chain)
  http_url: "https://api.hyperliquid.xyz",
  ws_url: "wss://api.hyperliquid.xyz/ws",

  # Optional features
  enable_db: false,
  enable_web: false,
  autostart_cache: true,

  # Debug logging
  debug: false,

  # Private key
  private_key: "YOUR_PRIVATE_KEY_HERE"
```

## Quick Start

### Fetching Market Data

Use Info API endpoints to retrieve market data:

```elixir
# Get mid prices for all assets
alias Hyperliquid.Api.Info.AllMids

{:ok, mids} = AllMids.request()
# Returns raw map: %{"BTC" => "43250.5", "ETH" => "2280.75", ...}

# Get account summary
alias Hyperliquid.Api.Info.ClearinghouseState

{:ok, state} = ClearinghouseState.request("0x1234...")
state.margin_summary.account_value
# => "10000.0"

# Get open orders
alias Hyperliquid.Api.Info.FrontendOpenOrders

{:ok, orders} = FrontendOpenOrders.request("0x1234...")
# => [%{coin: "BTC", limit_px: "43000.0", ...}]

# Get user fills
alias Hyperliquid.Api.Info.UserFills

{:ok, fills} = UserFills.request("0x1234...")
# => %{fills: [%{coin: "BTC", px: "43100.5", ...}]}
```

### Placing Orders

Use Exchange API endpoints to trade:

```elixir
alias Hyperliquid.Api.Exchange.{Order, Cancel}

# Get your private key from config
private_key = Application.get_env(:hyperliquid, :private_key)

# Place a limit order (all-in-one)
{:ok, result} = Order.place_limit(private_key, "BTC", true, "43000.0", "0.1")
# => %{status: "ok", response: %{data: %{statuses: [%{resting: %{oid: 12345}}]}}}

# Place a market order
{:ok, result} = Order.place_market(private_key, "ETH", false, "1.5")

# Or build and place separately
order = Order.limit_order("BTC", true, "43000.0", "0.1")
{:ok, result} = Order.place(private_key, order)

# Cancel an order by asset and order ID
{:ok, cancel_result} = Cancel.cancel(private_key, 0, 12345)
# => %{status: "ok", response: %{data: %{statuses: ["success"]}}}
```

### WebSocket Subscriptions

Subscribe to real-time data feeds:

```elixir
alias Hyperliquid.WebSocket.Manager
alias Hyperliquid.Api.Subscription.{AllMids, Trades, UserFills}

# Subscribe to all mid prices (shared connection)
{:ok, sub_id} = Manager.subscribe(AllMids, %{})

# Subscribe to trades for BTC (shared connection)
{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"})

# Subscribe to user fills (user-grouped connection)
{:ok, sub_id} = Manager.subscribe(UserFills, %{user: "0x1234..."})

# Unsubscribe
Manager.unsubscribe(sub_id)

# List active subscriptions
Manager.list_subscriptions()
```

### Using the Cache

The cache provides fast access to asset metadata and mid prices:

```elixir
alias Hyperliquid.Cache

# The cache auto-initializes on startup (unless autostart_cache: false)
# Manual initialization:
Cache.init()

# Get mid price for a coin
Cache.get_mid("BTC")
# => 43250.5

# Get asset index for a coin
Cache.asset_from_coin("BTC")
# => 0

Cache.asset_from_coin("HYPE/USDC")  # Spot pairs work too
# => 10107

# Get size decimals
Cache.decimals_from_coin("BTC")
# => 5

# Get token info
Cache.get_token_by_name("HFUN")
# => %{"name" => "HFUN", "index" => 2, "sz_decimals" => 2, ...}

# Subscribe to live mid price updates
{:ok, sub_id} = Cache.subscribe_to_mids()
```

## API Reference

### Info API (Market & Account Data)

The Info API provides read-only market and account information. All endpoints are located in `Hyperliquid.Api.Info.*`:

**Market Data:**
- `AllMids` - Mid prices for all assets
- `AllPerpMetas` - Perpetual market metadata
- `ActiveAssetData` - Asset context data
- `CandleSnapshot` - Historical candles
- `FundingHistory` - Funding rate history
- `L2Book` - Order book snapshot

**Account Data:**
- `ClearinghouseState` - Perpetuals account summary
- `SpotClearinghouseState` - Spot account summary
- `UserFills` - Trade fill history
- `HistoricalOrders` - Historical orders
- `FrontendOpenOrders` - Current open orders
- `UserFunding` - User funding payments

**Vault & Delegation:**
- `VaultDetails` - Vault information
- `Delegations` - User delegations
- `DelegatorRewards` - Delegation rewards

See the [HexDocs](https://hexdocs.pm/hyperliquid) for the complete list of 61 Info endpoints.

### Exchange API (Trading Operations)

The Exchange API handles all trading operations. All endpoints are located in `Hyperliquid.Api.Exchange.*`:

**Order Management:**
- `Modify` - Place or modify orders
- `BatchModify` - Batch order modifications
- `Cancel` - Cancel orders
- `CancelByCloid` - Cancel by client order ID

**Account Operations:**
- `UsdTransfer` - Transfer USD between accounts
- `Withdraw3` - Withdraw to L1
- `CreateSubAccount` - Create sub-accounts
- `UpdateLeverage` - Adjust position leverage
- `UpdateIsolatedMargin` - Modify isolated margin

**Vault Operations:**
- `CreateVault` - Create a new vault
- `VaultTransfer` - Vault deposits/withdrawals

See the [HexDocs](https://hexdocs.pm/hyperliquid) for the complete list of 38 Exchange endpoints.

### Subscription API (Real-time Updates)

The Subscription API provides WebSocket channels for real-time data. All endpoints are located in `Hyperliquid.Api.Subscription.*`:

**Market Subscriptions:**
- `AllMids` - All mid prices (shared connection)
- `Trades` - Recent trades (shared connection)
- `L2Book` - Order book updates (dedicated connection)
- `Candle` - Real-time candles (shared connection)

**User Subscriptions:**
- `UserFills` - User trade fills (user-grouped)
- `UserFundings` - Funding payments (user-grouped)
- `OrderUpdates` - Order status changes (user-grouped)
- `Notification` - User notifications (user-grouped)

**Explorer Subscriptions:**
- `ExplorerBlock` - New blocks (shared connection)
- `ExplorerTxs` - Transactions (shared connection)

See the [HexDocs](https://hexdocs.pm/hyperliquid) for the complete list of 26 subscription channels.

## Endpoint DSL

All API endpoints are defined using declarative macros that eliminate boilerplate:

### Info/Exchange Endpoints

```elixir
defmodule Hyperliquid.Api.Info.AllMids do
  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "allMids",
    optional_params: [:dex],
    rate_limit_cost: 2,
    raw_response: true

  embedded_schema do
    field(:mids, :map)
    field(:dex, :string)
  end

  def changeset(struct \\ %__MODULE__{}, attrs) do
    # Validation logic
  end
end
```

This automatically generates:
- `request/0`, `request/1` - Make API request, return `{:ok, result}` or `{:error, reason}`
- `request!/0`, `request!/1` - Bang variant that raises on error
- `build_request/1` - Build request parameters
- `parse_response/1` - Parse and validate response
- `rate_limit_cost/0` - Get rate limit cost

### Subscription Endpoints

```elixir
defmodule Hyperliquid.Api.Subscription.Trades do
  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "trades",
    params: [:coin],
    connection_type: :shared,
    storage: [
      postgres: [enabled: true, table: "trades"],
      cache: [enabled: true, ttl: :timer.minutes(5)]
    ]

  embedded_schema do
    embeds_many :trades, Trade do
      field(:coin, :string)
      field(:px, :string)
      # ...
    end
  end

  def changeset(event \\ %__MODULE__{}, attrs) do
    # Validation logic
  end
end
```

This automatically generates:
- `build_request/1` - Build subscription request
- `__subscription_info__/0` - Metadata about the subscription
- `generate_subscription_key/1` - Unique key for connection routing

## WebSocket Management

The `Hyperliquid.WebSocket.Manager` handles all WebSocket connections and subscriptions:

### Connection Strategies

- **`:shared`** - Multiple subscriptions share one connection (e.g., `AllMids`, `Trades`)
- **`:dedicated`** - Each subscription gets its own connection (e.g., `L2Book` with params)
- **`:user_grouped`** - All subscriptions for the same user share one connection (e.g., `UserFills`)

### Subscribe with Callbacks

```elixir
alias Hyperliquid.WebSocket.Manager
alias Hyperliquid.Api.Subscription.Trades

# Subscribe with callback function
callback = fn event ->
  IO.inspect(event, label: "Trade event")
end

{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"}, callback)
```

### Phoenix PubSub Integration

All WebSocket events are broadcast via Phoenix.PubSub:

```elixir
# Subscribe to events in your LiveView or GenServer
Phoenix.PubSub.subscribe(Hyperliquid.PubSub, "ws_event")

# Or use the utility function
Hyperliquid.Utils.subscribe("ws_event")

# Handle events
def handle_info({:ws_event, event}, state) do
  # Process event
  {:noreply, state}
end
```

## Caching

The cache module provides efficient access to frequently-used data:

### Automatic Updates

When `autostart_cache: true` (default), the cache automatically:
- Fetches exchange metadata on startup
- Populates asset mappings and decimal precision
- Updates mid prices from WebSocket subscriptions

### Cache Functions

```elixir
alias Hyperliquid.Cache

# Asset lookups
Cache.asset_from_coin("BTC")         # => 0
Cache.decimals_from_coin("BTC")      # => 5
Cache.get_mid("BTC")                 # => 43250.5

# Metadata
Cache.perps()                        # => [%{"name" => "BTC", ...}, ...]
Cache.spot_pairs()                   # => [%{"name" => "@0", ...}, ...]
Cache.tokens()                       # => [%{"name" => "USDC", ...}, ...]

# Token lookups
Cache.get_token_by_name("HFUN")      # => %{"index" => 2, ...}
Cache.get_token_key("HFUN")          # => "HFUN:0xbaf265..."

# Low-level cache access
Cache.get(:all_mids)                 # => %{"BTC" => "43250.5", ...}
Cache.put(:my_key, value)
Cache.exists?(:my_key)               # => true
```

## Database Integration

When `enable_db: true`, the package provides Postgres persistence:

### Setup

```bash
# Install database dependencies
mix deps.get

# Create and migrate database
mix ecto.create
mix ecto.migrate
```

### Repo Configuration

```elixir
# config/config.exs
config :hyperliquid, ecto_repos: [Hyperliquid.Repo]

config :hyperliquid, Hyperliquid.Repo,
  database: "hyperliquid_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
```

### Storage Layer

Endpoints with `storage` configuration automatically persist data:

```elixir
# This subscription will automatically store trades in Postgres and Cachex
alias Hyperliquid.Api.Subscription.Trades

{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"})

# Query stored data
import Ecto.Query
alias Hyperliquid.Repo

query = from t in "trades",
  where: t.coin == "BTC",
  order_by: [desc: t.time],
  limit: 10

Repo.all(query)
```

### Migrations

Database migrations are located in `priv/repo/migrations/`. The package includes migrations for:
- `trades`, `fills`, `orders`, `historical_orders`
- `clearinghouse_states`, `user_snapshots`
- `explorer_blocks`, `transactions`
- `candles`

## Livebook

Use Hyperliquid in Livebook for interactive trading and analysis:

```elixir
Mix.install([
  {:hyperliquid, "~> 0.2.0"}
],
config: [
  hyperliquid: [
    private_key: "YOUR_PRIVATE_KEY_HERE"
  ]
])

# Start working with the API
alias Hyperliquid.Api.Info.AllMids
{:ok, mids} = AllMids.request()
```

### Testnet in Livebook

```elixir
Mix.install([
  {:hyperliquid, "~> 0.2.0"}
],
config: [
  hyperliquid: [
    chain: :testnet,
    private_key: "YOUR_TESTNET_KEY"
  ]
])
```

## Development

```bash
# Get dependencies
mix deps.get

# Run tests
mix test

# Run tests with database
mix test

# Format code
mix format

# Generate docs
mix docs
```

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/hyperliquid).

## License

This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.
