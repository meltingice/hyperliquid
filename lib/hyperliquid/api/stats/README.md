# Stats API Module

This module provides access to Hyperliquid's stats endpoints for leaderboard and vaults data.

## Files

- **`leaderboard.ex`** - Trading leaderboard with account values, performance metrics, and rankings
- **`vaults.ex`** - Vault performance metrics, APR, PnL history, and summary information

## Quick Start

```elixir
# Fetch leaderboard
{:ok, leaderboard} = Hyperliquid.Api.Stats.Leaderboard.request()

# Fetch vaults
{:ok, vaults} = Hyperliquid.Api.Stats.Vaults.request()
```

## Features

### Leaderboard
- Get trader count
- Find specific traders by address
- Get top N traders
- Access performance metrics by time window (day, week, month, allTime)

### Vaults
- Get vault count
- Find specific vaults by address
- Sort by APR or TVL
- Filter by open/closed status
- Access PnL data by time window

## Configuration

The stats endpoints automatically use the configured chain (mainnet/testnet):

```elixir
config :hyperliquid,
  chain: :mainnet,
  chains: %{
    mainnet: %{stats_url: "https://stats-data.hyperliquid.xyz"},
    testnet: %{stats_url: "https://stats-data.hyperliquid-testnet.xyz"}
  }
```

## Documentation

See [docs/stats_api.md](../../docs/stats_api.md) for detailed usage examples and API reference.

## Tests

Run tests with:
```bash
mix test test/stats_test.exs
```
