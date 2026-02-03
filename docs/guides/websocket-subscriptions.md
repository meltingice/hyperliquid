# WebSocket Subscriptions

## Subscribing

```elixir
alias Hyperliquid.WebSocket.Manager

# Basic subscription
{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"})

# With callback
{:ok, sub_id} = Manager.subscribe(Trades, %{coin: "BTC"}, fn event ->
  IO.inspect(event, label: "trade")
end)
```

## Connection Strategies

### Shared Connections

Multiple subscriptions share a single WebSocket. Used for high-throughput market data.

```elixir
# Both use the same underlying connection
Manager.subscribe(AllMids, %{})
Manager.subscribe(Trades, %{coin: "BTC"})
Manager.subscribe(Trades, %{coin: "ETH"})
```

### Dedicated Connections

Each subscription gets its own connection. Used when params define a unique data stream.

```elixir
# Each gets a separate connection
Manager.subscribe(L2Book, %{coin: "BTC"})
Manager.subscribe(L2Book, %{coin: "ETH"})
```

### User-Grouped Connections

All subscriptions for the same user share one connection.

```elixir
# Same connection for this user
Manager.subscribe(UserFills, %{user: "0x1234..."})
Manager.subscribe(OrderUpdates, %{user: "0x1234..."})
```

## Managing Subscriptions

```elixir
# List all
Manager.list_subscriptions()

# Get details
{:ok, sub} = Manager.get_subscription(sub_id)

# Get metrics (message count, rate, etc.)
{:ok, metrics} = Manager.get_metrics(sub_id)
Manager.list_all_metrics()

# Connection info
Manager.connection_info()

# Unsubscribe
Manager.unsubscribe(sub_id)
```

## Phoenix PubSub

All WebSocket events are broadcast via PubSub, so you can receive them in LiveViews or GenServers:

```elixir
# In a LiveView or GenServer
Phoenix.PubSub.subscribe(Hyperliquid.PubSub, "ws_event")

def handle_info({:ws_event, event}, state) do
  # Process the event
  {:noreply, state}
end
```

Or use the convenience helper:

```elixir
Hyperliquid.Utils.subscribe("ws_event")
```
