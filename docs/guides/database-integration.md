# Database Integration

Optional Postgres persistence for API and subscription data.

## Setup

1. Add database dependencies to `mix.exs`:

```elixir
{:phoenix_ecto, "~> 4.5"},
{:ecto_sql, "~> 3.10"},
{:postgrex, ">= 0.0.0"}
```

2. Configure:

```elixir
config :hyperliquid,
  enable_db: true

config :hyperliquid, ecto_repos: [Hyperliquid.Repo]

config :hyperliquid, Hyperliquid.Repo,
  database: "hyperliquid_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
```

3. Create and migrate the database:

```bash
mix ecto.create
mix ecto.migrate
```

## How It Works

Endpoints with `storage` configuration automatically persist data. The `Storage.Writer` GenServer batches inserts for efficiency.

```elixir
# Subscribing to trades auto-stores them in Postgres
{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"})
```

## Querying Stored Data

```elixir
import Ecto.Query
alias Hyperliquid.Repo

query = from t in "trades",
  where: t.coin == "BTC",
  order_by: [desc: t.time],
  limit: 10

Repo.all(query)
```

## Testnet

When using `chain: :testnet`, the database name automatically gets a `_testnet` suffix to keep data separate.

## Available Tables

The package includes migrations for: `trades`, `fills`, `orders`, `historical_orders`, `clearinghouse_states`, `user_snapshots`, `explorer_blocks`, `transactions`, and `candles`.
