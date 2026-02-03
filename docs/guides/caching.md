# Caching

The SDK uses Cachex for fast in-memory access to asset metadata and mid prices.

## Automatic Initialization

By default (`autostart_cache: true`), the cache populates on application startup with:

- Perpetual and spot market metadata
- Asset name-to-index mappings
- Size and price decimal precision
- Token metadata
- Current mid prices

## Common Lookups

```elixir
alias Hyperliquid.Cache

Cache.get_mid("BTC")              # => 43250.5
Cache.asset_from_coin("BTC")      # => 0
Cache.coin_from_asset(0)          # => "BTC"
Cache.decimals_from_coin("BTC")   # => 5
Cache.spot_pair_id("HYPE/USDC")   # => "10107"
Cache.get_token_by_name("HFUN")   # => %{"name" => "HFUN", ...}
Cache.get_token_key("HFUN")       # => "HFUN:0xbaf265..."
```

## Metadata Access

```elixir
Cache.perp_meta()      # Full perpetual metadata
Cache.spot_meta()      # Full spot metadata
Cache.perps()          # List of perp assets
Cache.spot_pairs()     # List of spot pairs
Cache.tokens()         # List of tokens
```

## Live Price Updates

Subscribe to real-time mid price updates via WebSocket:

```elixir
{:ok, sub_id} = Cache.subscribe_to_mids()
```

Schedule periodic cache refreshes:

```elixir
{:ok, timer_ref} = Cache.schedule_refresh(interval: :timer.minutes(5))
```

## Manual Initialization

If `autostart_cache: false`:

```elixir
# Full init (fails if any key fails)
:ok = Cache.init()

# Partial success mode
{:ok, :partial, failed_keys} = Cache.init_with_partial_success()
```

## Low-Level Access

```elixir
Cache.get(:all_mids)
Cache.put(:my_key, value)
Cache.exists?(:my_key)
Cache.del(:my_key)
Cache.clear()
```
