# Architecture

## Supervision Tree

```
Hyperliquid.Application
├── Phoenix.PubSub (Hyperliquid.PubSub)
├── Cachex (:hyperliquid_cache)
├── Hyperliquid.Rpc.Registry
├── Hyperliquid.WebSocket.Supervisor (DynamicSupervisor)
├── Hyperliquid.Cache.Warmer          (if autostart_cache: true)
├── Hyperliquid.Repo                  (if enable_db: true)
└── Hyperliquid.Storage.Writer        (if enable_db: true)
```

## Module Layers

```
┌─────────────────────────────────────┐
│         User Application            │
├─────────────────────────────────────┤
│  Api.Info.*  Api.Exchange.*         │  Endpoint modules (DSL-generated)
│  Api.Subscription.*  Api.Explorer.* │
├─────────────────────────────────────┤
│  Cache       WebSocket.Manager      │  Caching & connection management
├─────────────────────────────────────┤
│  Transport.Http    Transport.Rpc    │  HTTP & JSON-RPC transport
│  WebSocket.Connection               │
├─────────────────────────────────────┤
│  Signer (Rust NIF)                  │  Cryptographic signing
├─────────────────────────────────────┤
│  Storage.Writer    Repo             │  Optional persistence
└─────────────────────────────────────┘
```

## Key Design Patterns

- **DSL-based generation**: Macros eliminate boilerplate while keeping endpoints explicit and inspectable
- **Ecto schemas for validation**: All API responses are cast through changesets for type safety
- **Connection pooling**: WebSocket Manager routes subscriptions to shared, dedicated, or user-grouped connections
- **Optional persistence**: Database and storage features are entirely config-driven
- **Telemetry-first**: Every operation emits telemetry events for observability
- **Rust NIFs for signing**: Performance-critical EIP-712 cryptography runs as native code
- **Graceful degradation**: Cache initialization supports partial success modes
