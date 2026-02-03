# Subscription API

The Subscription API provides real-time WebSocket data feeds. All modules are under `Hyperliquid.Api.Subscription.*`.

## Connection Types

Each subscription uses one of three connection strategies:

| Type | Behavior | Example |
|------|----------|---------|
| `:shared` | Multiple subscriptions share one connection | AllMids, Trades |
| `:dedicated` | Each subscription gets its own connection | L2Book |
| `:user_grouped` | All subs for the same user share one connection | UserFills, OrderUpdates |

## Market Subscriptions

| Module | Connection | Parameters | Description |
|--------|-----------|-----------|-------------|
| `AllMids` | shared | - | All mid prices |
| `Trades` | shared | `coin` | Recent trades |
| `L2Book` | dedicated | `coin` | Order book updates |
| `Candle` | shared | `coin, interval` | Real-time candles |

## User Subscriptions

| Module | Connection | Parameters | Description |
|--------|-----------|-----------|-------------|
| `UserFills` | user_grouped | `user` | Trade fills |
| `UserFundings` | user_grouped | `user` | Funding payments |
| `OrderUpdates` | user_grouped | `user` | Order status changes |
| `Notification` | user_grouped | `user` | Notifications |
| `UserNonFundingLedgerUpdates` | user_grouped | `user` | Non-funding ledger updates |
| `UserTwapHistory` | user_grouped | `user` | TWAP order history |
| `UserTwapSliceFills` | user_grouped | `user` | TWAP slice fills |

## Explorer Subscriptions

| Module | Connection | Description |
|--------|-----------|-------------|
| `ExplorerBlock` | shared | New blocks |
| `ExplorerTxs` | shared | Transactions |

## Usage

```elixir
alias Hyperliquid.WebSocket.Manager

# Subscribe
{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"})

# Subscribe with callback
{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"}, fn event ->
  IO.inspect(event)
end)

# List subscriptions
Manager.list_subscriptions()

# Get metrics
{:ok, metrics} = Manager.get_metrics(sub_id)

# Unsubscribe
Manager.unsubscribe(sub_id)
```

## PubSub Integration

All events are broadcast via Phoenix PubSub:

```elixir
Phoenix.PubSub.subscribe(Hyperliquid.PubSub, "ws_event")

def handle_info({:ws_event, event}, state) do
  # Process event
  {:noreply, state}
end
```

For the complete list of 26 subscription channels, see the [HexDocs](https://hexdocs.pm/hyperliquid).
