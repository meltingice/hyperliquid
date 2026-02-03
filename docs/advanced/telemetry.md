# Telemetry & Observability

The SDK emits `:telemetry` events for all major operations.

## Quick Setup

```elixir
Hyperliquid.Telemetry.attach_default_logger()
```

## Events

### API

| Event | Description |
|-------|-------------|
| `[:hyperliquid, :api, :request, :start]` | Info request started |
| `[:hyperliquid, :api, :request, :stop]` | Info request completed |
| `[:hyperliquid, :api, :request, :exception]` | Info request failed |
| `[:hyperliquid, :api, :exchange, :start]` | Exchange request started |
| `[:hyperliquid, :api, :exchange, :stop]` | Exchange request completed |
| `[:hyperliquid, :api, :exchange, :exception]` | Exchange request failed |

### WebSocket

| Event | Description |
|-------|-------------|
| `[:hyperliquid, :ws, :connect, :start\|:stop\|:exception]` | Connection lifecycle |
| `[:hyperliquid, :ws, :message, :received]` | Message received |
| `[:hyperliquid, :ws, :disconnect]` | Connection lost |
| `[:hyperliquid, :ws, :subscribe]` | Subscription added |
| `[:hyperliquid, :ws, :unsubscribe]` | Subscription removed |

### Cache

| Event | Description |
|-------|-------------|
| `[:hyperliquid, :cache, :init, :stop\|:exception]` | Cache initialization |
| `[:hyperliquid, :cache, :refresh, :stop]` | Cache refresh |

### RPC

| Event | Description |
|-------|-------------|
| `[:hyperliquid, :rpc, :request, :start\|:stop\|:exception]` | RPC calls |

### Storage

| Event | Description |
|-------|-------------|
| `[:hyperliquid, :storage, :flush, :stop]` | Buffer flush |

## Telemetry.Metrics Example

```elixir
defmodule MyApp.Telemetry do
  import Telemetry.Metrics

  def metrics do
    [
      summary("hyperliquid.api.request.stop.duration", unit: {:native, :millisecond}),
      summary("hyperliquid.api.exchange.stop.duration", unit: {:native, :millisecond}),
      counter("hyperliquid.ws.message.received.count"),
      summary("hyperliquid.rpc.request.stop.duration", unit: {:native, :millisecond}),
      last_value("hyperliquid.storage.flush.stop.record_count")
    ]
  end
end
```
