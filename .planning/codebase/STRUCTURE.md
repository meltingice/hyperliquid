# Codebase Structure

**Analysis Date:** 2026-01-21

## Directory Layout

```
lib/hyperliquid/
├── api/                          # API endpoint definitions and routing
│   ├── info/                      # Info API endpoints (~58 modules)
│   ├── exchange/                  # Exchange action endpoints (~40 modules)
│   ├── explorer/                  # Explorer endpoints (3 modules)
│   ├── subscription/              # WebSocket subscription types (~30 modules)
│   ├── stats/                     # Stats endpoints (2 modules)
│   ├── api.ex                     # Root API module with command/3 interface
│   ├── endpoint.ex                # DSL macro for defining endpoints
│   ├── exchange.ex                # Exchange convenience function wrapper
│   ├── info.ex                    # Info convenience function wrapper
│   ├── common.ex                  # Shared utilities for endpoints
│   ├── exchange_endpoint.ex       # Legacy exchange endpoint base
│   ├── subscription_endpoint.ex   # WebSocket subscription endpoint DSL
│   ├── registry.ex                # Endpoint registry and discovery
│   └── stats_endpoint.ex          # Stats endpoint specialization
├── transport/                     # Network communication layer
│   ├── http.ex                    # HTTP client with snake_case conversion
│   ├── rpc.ex                     # Ethereum JSON-RPC client
│   └── websocket.ex               # WebSocket connection handling
├── websocket/                     # Subscription and real-time data
│   ├── manager.ex                 # Subscription lifecycle manager
│   ├── connection.ex              # Individual WebSocket connection handler
│   └── supervisor.ex              # Dynamic supervisor for connections
├── storage/                       # Data persistence
│   └── writer.ex                  # Async/sync storage to PostgreSQL and cache
├── rpc/                           # RPC method modules
│   ├── custom.ex                  # Custom RPC methods
│   ├── eth.ex                     # Ethereum JSON-RPC methods
│   ├── net.ex                     # Network RPC methods
│   ├── web3.ex                    # Web3 RPC methods
│   └── registry.ex                # RPC registry
├── utils/                         # Shared utilities
│   ├── format.ex                  # Formatting helpers
│   └── interval.ex                # Interval utilities
├── application.ex                 # OTP application entry point
├── cache.ex                       # Cachex wrapper for cache operations
├── config.ex                      # Environment configuration
├── error.ex                       # Error struct definition
├── repo.ex                        # Ecto repository for database access
├── signer.ex                      # Cryptographic signing for transactions
└── hyperliquid.ex                 # Root module placeholder

test/
├── hyperliquid_test.exs           # Main test file
├── support/
│   └── *.ex                       # Test helpers and fixtures

config/
├── config.exs                     # Base configuration
├── test.exs                       # Test environment config
└── dev.exs                        # Development environment config

mix.exs                            # Project manifest with deps
```

## Directory Purposes

**`api/`:**
- Purpose: API endpoint definitions and context-specific routing
- Contains: Ecto schema modules for each API endpoint, context wrappers (Info, Exchange), Registry, DSL macros
- Key files: `endpoint.ex` (DSL), `registry.ex` (discovery), subdirectories by context

**`api/info/`:**
- Purpose: Info API endpoint implementations (~58 endpoints)
- Contains: Read-only endpoints for market data, user state, metadata
- Key files: `all_mids.ex`, `l2_book.ex`, `open_orders.ex`, `portfolio.ex` (examples)
- Pattern: Each file defines one endpoint using `Hyperliquid.Api.Endpoint` DSL

**`api/exchange/`:**
- Purpose: Exchange action endpoint implementations (~40 endpoints)
- Contains: Write operations for orders, transfers, account management
- Key files: `order.ex`, `cancel.ex`, `modify.ex` (examples)
- Pattern: Legacy implementation pattern (not yet migrated to DSL), direct request/response handling

**`api/subscription/`:**
- Purpose: WebSocket subscription endpoint types (~30 modules)
- Contains: Subscription definitions for real-time updates
- Key files: `trades.ex`, `l2_book.ex`, `order_updates.ex` (examples)
- Pattern: Uses `Hyperliquid.Api.SubscriptionEndpoint` DSL similar to HTTP endpoints

**`transport/`:**
- Purpose: Low-level network communication abstraction
- Contains: HTTP client, WebSocket connections, Ethereum RPC
- Key files: `http.ex` (HTTPoison wrapper), `websocket.ex` (WebSocket connection), `rpc.ex` (JSON-RPC)
- Pattern: Each module handles request/response transformation and error handling

**`websocket/`:**
- Purpose: Subscription lifecycle and connection management
- Contains: Manager for subscriptions, Connection handlers, DynamicSupervisor
- Key files: `manager.ex` (subscription registry), `connection.ex` (WS handler)
- Pattern: GenServer-based, ETS for subscription tracking

**`storage/`:**
- Purpose: Persistence of API responses to multiple backends
- Contains: Writer GenServer with batching and flushing
- Key files: `writer.ex` (async/sync storage operations)
- Pattern: Batches writes, supports PostgreSQL (via Repo) and Cachex

**`rpc/`:**
- Purpose: RPC method implementations for blockchain operations
- Contains: Methods for Ethereum JSON-RPC, custom methods, network info
- Key files: `eth.ex` (standard Ethereum methods), `custom.ex` (Hyperliquid-specific)
- Pattern: Each module groups related RPC methods

## Key File Locations

**Entry Points:**
- `lib/hyperliquid/application.ex`: OTP application supervision tree, initializes all services
- `lib/hyperliquid/api.ex`: Root API module with `command/3` interface for dynamic endpoint invocation
- `lib/hyperliquid/api/registry.ex`: Endpoint discovery and metadata lookup

**Configuration:**
- `lib/hyperliquid/config.ex`: Centralized configuration with environment overrides
- `config/config.exs`: Base Elixir configuration
- `mix.exs`: Project definition and dependency management

**Core Logic:**
- `lib/hyperliquid/api/endpoint.ex`: DSL macro for HTTP endpoint definitions
- `lib/hyperliquid/api/subscription_endpoint.ex`: DSL macro for WebSocket subscriptions
- `lib/hyperliquid/transport/http.ex`: HTTP communication with snake_case conversion
- `lib/hyperliquid/websocket/manager.ex`: Subscription lifecycle management

**Testing:**
- `test/hyperliquid_test.exs`: Main test suite
- `test/support/`: Test fixtures and helpers

## Naming Conventions

**Files:**
- Endpoint modules: Snake case matching API endpoint name (e.g., `all_mids.ex` for "allMids" endpoint)
- Context modules: Snake case matching context (e.g., `info.ex`, `exchange.ex`)
- Transport/infrastructure: Descriptive names (e.g., `http.ex`, `websocket.ex`)

**Directories:**
- API subdirectories: Lowercase context names (`info/`, `exchange/`, `explorer/`, `subscription/`, `stats/`)
- Support directories: Descriptive plural names (`utils/`, `websocket/`, `storage/`, `rpc/`)

**Module Names:**
- Endpoint modules: CamelCase based on file name (e.g., `Hyperliquid.Api.Info.AllMids`)
- Context modules: CamelCase context name (e.g., `Hyperliquid.Api.Info`, `Hyperliquid.Api.Exchange`)
- Utilities: Descriptive CamelCase (e.g., `Hyperliquid.Transport.Http`, `Hyperliquid.WebSocket.Manager`)

**Functions:**
- Public API: `request/0,1,2`, `request!/0,1,2` (endpoint functions)
- Endpoint building: `build_request/0,1,2`
- Parsing: `parse_response/1`, `changeset/2`
- Convenience wrappers: Snake case matching endpoint name (e.g., `all_mids()`, `l2_book()`)

## Where to Add New Code

**New Info Endpoint:**
1. Create `lib/hyperliquid/api/info/{endpoint_name}.ex`
2. Define module using `use Hyperliquid.Api.Endpoint, type: :info, ...`
3. Define Ecto schema with `embedded_schema do` block
4. Implement `changeset/2` for validation
5. Add to `@endpoints_by_context[:info]` list in `lib/hyperliquid/api/registry.ex`

**New Exchange Endpoint (Legacy):**
1. Create `lib/hyperliquid/api/exchange/{endpoint_name}.ex`
2. Define module using `use Hyperliquid.Api.ExchangeEndpoint` (legacy)
3. Implement request building and response parsing
4. Add to registry

**New WebSocket Subscription:**
1. Create `lib/hyperliquid/api/subscription/{subscription_name}.ex`
2. Define module using `use Hyperliquid.Api.SubscriptionEndpoint`
3. Define response schema and parsing
4. Register in WebSocket.Manager connection type routing

**New Transport Protocol:**
1. Create `lib/hyperliquid/transport/{protocol_name}.ex`
2. Implement low-level communication details
3. Reference from API layer modules

**Shared Utility:**
1. Create or update in `lib/hyperliquid/utils/{utility_name}.ex`
2. Keep focused on a single concern (formatting, intervals, etc.)

**New RPC Method:**
1. Create or update in `lib/hyperliquid/rpc/{category}.ex`
2. Group related methods in same module
3. Register in `lib/hyperliquid/rpc/registry.ex`

## Special Directories

**`api/`:**
- Purpose: Organized by API context (info, exchange, explorer, stats, subscription)
- Generated: No, all hand-written
- Committed: Yes, all committed to version control

**`deps/`:**
- Purpose: External dependencies managed by Mix
- Generated: Yes, by `mix deps.get`
- Committed: No, generated directory excluded from version control

**`_build/`:**
- Purpose: Compiled artifacts and build output
- Generated: Yes, by `mix compile`
- Committed: No, generated directory excluded from version control

**`.planning/`:**
- Purpose: GSD planning documents
- Generated: Yes, by planning tools
- Committed: No in typical GSD workflows, but can be committed if desired

---

*Structure analysis: 2026-01-21*
