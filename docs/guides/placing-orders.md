# Placing Orders

## Order Types

### Limit Orders

```elixir
alias Hyperliquid.Api.Exchange.Order

# Buy 0.1 BTC at $43,000
{:ok, result} = Order.place_limit("BTC", true, "43000.0", "0.1")

# Sell 1.0 ETH at $2,300
{:ok, result} = Order.place_limit("ETH", false, "2300.0", "1.0")
```

### Market Orders

```elixir
# Market buy 0.5 ETH
{:ok, result} = Order.place_market("ETH", true, "0.5")

# Market sell 0.1 BTC
{:ok, result} = Order.place_market("BTC", false, "0.1")
```

### Trigger Orders (Stop-Loss / Take-Profit)

```elixir
# Stop-loss: sell 0.1 BTC if price drops to $41,500
{:ok, result} = Order.place_trigger("BTC", false, "41000.0", "0.1",
  trigger_px: "41500.0", tp_sl: "sl")

# Take-profit: sell 0.1 BTC if price reaches $50,000
{:ok, result} = Order.place_trigger("BTC", false, "50500.0", "0.1",
  trigger_px: "50000.0", tp_sl: "tp")
```

## Building Orders Manually

```elixir
# Build order struct
order = Order.limit_order("BTC", true, "43000.0", "0.1")

# Place single order
{:ok, result} = Order.place(order)

# Batch multiple orders
orders = [
  Order.limit_order("BTC", true, "42000.0", "0.05"),
  Order.limit_order("BTC", true, "41000.0", "0.05")
]
{:ok, result} = Order.place_batch(orders, "na")
```

## Cancelling Orders

```elixir
alias Hyperliquid.Api.Exchange.{Cancel, CancelByCloid}

# Cancel by asset index and order ID
{:ok, _} = Cancel.cancel(0, 12345)

# Cancel by client order ID
{:ok, _} = CancelByCloid.request(0, "my-cloid-123")
```

## Modifying Orders

```elixir
alias Hyperliquid.Api.Exchange.Modify

{:ok, result} = Modify.request(order_id, new_order_params)
```

## Using Agent Keys

For trading bots, approve an agent key so you don't expose your main private key:

```elixir
alias Hyperliquid.Api.Exchange.ApproveAgent

# Approve agent (requires main key)
{:ok, _} = ApproveAgent.request(%{
  agent_address: "0xAgentAddress",
  agent_name: "my-bot"
}, private_key: "MAIN_PRIVATE_KEY")

# Then configure the agent key for trading
config :hyperliquid, private_key: "AGENT_PRIVATE_KEY"
```
