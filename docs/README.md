# Hyperliquid Elixir SDK

Elixir SDK for the [Hyperliquid](https://hyperliquid.xyz) decentralized exchange with DSL-based API endpoints, WebSocket subscriptions, and optional Postgres/Phoenix integration.

## Features

- **125+ typed endpoints** across Info, Exchange, Subscription, Explorer, and Stats APIs
- **DSL-based endpoint definitions** with automatic function generation and Ecto schema validation
- **WebSocket connection pooling** with shared, dedicated, and user-grouped strategies
- **Cachex-based caching** for asset metadata and mid price lookups
- **Optional Postgres persistence** for API and subscription data
- **Rust NIF signing** for high-performance EIP-712 cryptographic operations
- **Telemetry integration** for observability across all operations
- **Phoenix PubSub** for real-time event broadcasting

## Quick Example

```elixir
# Fetch mid prices
alias Hyperliquid.Api.Info.AllMids
{:ok, mids} = AllMids.request()

# Place a limit order
alias Hyperliquid.Api.Exchange.Order
{:ok, result} = Order.place_limit("BTC", true, "43000.0", "0.1")

# Subscribe to real-time trades
alias Hyperliquid.WebSocket.Manager
alias Hyperliquid.Api.Subscription.Trades
{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"})
```

## Navigation

Use the sidebar to browse the documentation, or start with [Installation](getting-started/installation.md).
