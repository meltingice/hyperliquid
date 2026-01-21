# Hyperliquid Elixir Library Hardening

## What This Is

Production hardening of the Hyperliquid Elixir API client library. Addressing tech debt, performance bottlenecks, and fragile areas identified in codebase analysis to prepare for release and scaled usage.

## Core Value

The library must be reliable under production load — no startup failures, no silent data loss, no performance degradation at scale.

## Requirements

### Validated

- ✓ DSL-based endpoint definitions for Info API — existing
- ✓ Multi-context architecture (info, exchange, explorer, stats) — existing
- ✓ WebSocket subscription management — existing
- ✓ Optional PostgreSQL and Cachex storage backends — existing
- ✓ Registry-based endpoint discovery — existing
- ✓ Telemetry events for observability — existing
- ✓ Ecto-based response validation — existing

### Active

- [ ] Replace debug IO.puts/IO.inspect with structured Logger calls
- [ ] Migrate Exchange endpoints to DSL-based architecture
- [ ] Extract shared delegation code from Info/Exchange modules
- [ ] Make cache initialization async (non-blocking startup)
- [ ] Add TTL and eviction policies to Cachex
- [ ] Improve WebSocket ETS subscription handling
- [ ] Add endpoint metadata validation/behavior enforcement
- [ ] Clarify NIF loading with better error messages
- [ ] Make HTTP timeouts configurable per endpoint
- [ ] Add tests for cache failure scenarios
- [ ] Add tests for timeout handling
- [ ] Add tests for macro-generated function signatures

### Out of Scope

- Schema generation task completion — deferred, not blocking release
- Full rate limiting implementation — tracked in CONCERNS.md, separate effort
- Batch request optimization — separate feature work
- Circuit breaker implementation — over-engineering for current needs
- Distributed cache (Redis/Memcached) — not needed yet

## Context

This is an existing Elixir library for interacting with Hyperliquid's trading API. The codebase was analyzed and concerns documented in `.planning/codebase/CONCERNS.md`. The library is functional but has accumulated technical debt and lacks hardening for production use.

**Current state:**
- Info endpoints use DSL pattern, Exchange endpoints use legacy pattern
- Cache blocks startup with sequential HTTP calls
- Debug output scattered throughout production code
- No eviction policy on cached data
- Fragile areas around NIF loading and endpoint introspection

**Technical environment:**
- Elixir 1.16+ on BEAM VM
- Optional Rust NIFs for cryptographic signing
- HTTPoison for HTTP, mint_web_socket for WebSocket
- Cachex for caching, Ecto for validation/persistence

## Constraints

- **Backwards compatibility**: Public API must remain stable — internal refactoring only
- **No new dependencies**: Use existing libraries (Logger, Cachex config, etc.)
- **Incremental migration**: Exchange DSL migration must not break existing callers

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Async cache init over parallel | Simpler, doesn't block app startup at all | — Pending |
| Full Exchange DSL migration | Consistency with Info pattern, enables code sharing | — Pending |
| Pragmatic fixes over comprehensive | Ship sooner, address real issues without over-engineering | — Pending |

---
*Last updated: 2026-01-21 after initialization*
