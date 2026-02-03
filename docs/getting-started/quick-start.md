# Quick Start

## Fetching Market Data

```elixir
alias Hyperliquid.Api.Info.{AllMids, ClearinghouseState, FrontendOpenOrders, L2Book}

# Mid prices for all assets
{:ok, mids} = AllMids.request()

# Account summary
{:ok, state} = ClearinghouseState.request("0xYourAddress")
state.margin_summary.account_value

# Open orders
{:ok, orders} = FrontendOpenOrders.request("0xYourAddress")

# Order book
{:ok, book} = L2Book.request("BTC")
```

## Placing Orders

```elixir
alias Hyperliquid.Api.Exchange.{Order, Cancel}

# Limit order: buy 0.1 BTC at $43,000
{:ok, result} = Order.place_limit("BTC", true, "43000.0", "0.1")

# Market order: sell 1.5 ETH
{:ok, result} = Order.place_market("ETH", false, "1.5")

# Cancel by asset index and order ID
{:ok, _} = Cancel.cancel(0, 12345)
```

## Real-Time Subscriptions

```elixir
alias Hyperliquid.WebSocket.Manager
alias Hyperliquid.Api.Subscription.{AllMids, Trades, UserFills}

# Subscribe to mid prices
{:ok, sub_id} = Manager.subscribe(AllMids, %{})

# Subscribe to BTC trades with a callback
{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"}, fn event ->
  IO.inspect(event, label: "trade")
end)

# Subscribe to your fills
{:ok, sub_id} = Manager.subscribe(UserFills, %{user: "0xYourAddress"})

# Unsubscribe
Manager.unsubscribe(sub_id)
```

## Using the Cache

```elixir
alias Hyperliquid.Cache

# Cache auto-initializes on startup (or call Cache.init() manually)
Cache.get_mid("BTC")            # => 43250.5
Cache.asset_from_coin("BTC")    # => 0
Cache.decimals_from_coin("BTC") # => 5
Cache.get_token_by_name("HFUN") # => %{"name" => "HFUN", ...}
```
