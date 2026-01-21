# Codebase Concerns

**Analysis Date:** 2026-01-21

## Tech Debt

**Debug Output Scattered Throughout Production Code:**
- Issue: Raw `IO.puts` and `IO.inspect` calls used for debugging instead of structured logging
- Files: `lib/hyperliquid/cache.ex` (lines 187-188), `lib/hyperliquid/api/exchange/modify.ex` (lines 70-71), `lib/hyperliquid/api/exchange/order.ex` (lines 597-598), `lib/hyperliquid/api/exchange/batch_modify.ex` (lines 188-189)
- Impact: Unstructured debug output pollutes stdout, cannot be filtered or routed, difficult to disable uniformly across codebase
- Fix approach: Replace all `IO.puts`/`IO.inspect` with Logger module using standard Elixir logging levels (debug, info, warn, error). Create centralized debug helper that respects config settings.

**Schema Generation Task Incomplete:**
- Issue: TypeScript/Valibot schema parser has multiple TODO markers for unimplemented parsing logic
- Files: `lib/mix/tasks/hyperliquid.gen.schemas.ex` (lines 208, 266, 275, 321, 326, 331)
- Impact: Cannot fully auto-generate schemas from TypeScript SDK, manual schema creation required, drift risk between SDK and Elixir types
- Fix approach: Complete Valibot parser to handle all schema types (full TypeScript/Valibot parser at line 208), implement request validation generation, extract import statements for nested types. Test against full SDK schema set.

**Exchange Endpoint DSL Migration In Progress:**
- Issue: Exchange endpoints not yet migrated to DSL-based architecture, using legacy pattern
- Files: `lib/hyperliquid/api/exchange.ex` (noted in moduledoc), all files in `lib/hyperliquid/api/exchange/` directory
- Impact: Inconsistent patterns across API (Info endpoints use DSL, Exchange uses legacy), maintenance burden, code generation opportunities not leveraged
- Fix approach: Systematically migrate each exchange endpoint module to use `Hyperliquid.Api.Endpoint` DSL. Start with high-frequency endpoints (Order, Modify, Cancel). Update registry and tests for each.

**Duplicate Function Generation Code:**
- Issue: Very similar macro code generated in both `lib/hyperliquid/api/exchange.ex` and `lib/hyperliquid/api/info.ex` for function delegation
- Files: `lib/hyperliquid/api/exchange.ex` (lines 34-191), `lib/hyperliquid/api/info.ex` (lines 38-307)
- Impact: Large code duplication (300+ lines), inconsistent updates if patterns change, maintenance liability
- Fix approach: Extract shared delegation logic into `Hyperliquid.Api.DelegationHelper` or similar module. Both exchange.ex and info.ex should call shared macros. Create comprehensive tests for delegation patterns.

## Security Considerations

**Private Key Exposure Risk in Config:**
- Risk: Private key stored in Application config accessible via `Config.secret/0`, no encryption at rest
- Files: `lib/hyperliquid/config.ex` (lines 127-132), potential usage throughout signer modules
- Current mitigation: Config is application-level (not persisted), documentation notes security
- Recommendations: Implement secrets encryption layer (e.g., using VaultEx or similar), add runtime key derivation where possible, log warnings if private keys are returned from config, provide guidance on secure key storage using environment variables or external secret services.

**Bridge Contract Address Hardcoded:**
- Risk: Default bridge contract address hardcoded in config, could be mistakenly used with different contract
- Files: `lib/hyperliquid/config.ex` (line 138)
- Current mitigation: Address is for mainnet only, config can override
- Recommendations: Require explicit bridge contract configuration rather than defaulting, add validation that contract address matches expected mainnet/testnet, consider storing contract ABI/version info alongside address.

**RPC Endpoint Configuration Without Validation:**
- Risk: Named RPC endpoints configuration accepts any URL without validation or verification
- Files: `lib/hyperliquid/config.ex` (lines 176-178), `lib/hyperliquid/rpc/registry.ex`
- Current mitigation: None detected
- Recommendations: Add URL format validation on registration, implement RPC endpoint health checks before accepting requests, add rate-limiting per endpoint, warn if using HTTP instead of HTTPS for mainnet.

## Performance Bottlenecks

**Cache Initialization Network Serialization:**
- Problem: `Cache.init/0` makes sequential HTTP calls to fetch metadata, blocking startup
- Files: `lib/hyperliquid/cache.ex` (lines 52-183)
- Cause: Uses `with` chains that execute sequentially (Meta → AllMids → PerDEX metas). For each builder DEX, makes separate HTTP request (line 90). All must complete before cache available.
- Improvement path: Parallelize metadata fetches using Task.async_stream or similar, implement timeout with fallback to partial cache, consider pre-warming cache data from file, add metrics to measure initialization time.

**Endpoint Registry Compile-Time Resolution:**
- Problem: `Hyperliquid.Api.Info` and `Hyperliquid.Api.Exchange` use compile-time code generation via `Registry.list_context_endpoints/1` to create 100+ functions
- Files: `lib/hyperliquid/api/info.ex` (lines 38-307), `lib/hyperliquid/api/exchange.ex` (lines 34-191)
- Cause: Quote/unquote macros generate function clauses at compile time for every registered endpoint, creating large modules and long compile times
- Improvement path: Consider runtime function delegation using `apply/3` with cached module resolution, profile compile times to verify if this is actual issue, evaluate cost-benefit of compile-time generation vs. runtime flexibility.

**Cachex Without Eviction Policy:**
- Problem: `Cache` module stores unlimited data in Cachex without TTL or eviction strategy
- Files: `lib/hyperliquid/cache.ex` (lines 152-174)
- Cause: All cache puts use `Cachex.put!` without `:ttl` option, stores mutable data (mids) indefinitely
- Improvement path: Add configurable TTL for mutable data (all_mids should refresh every 5 minutes), implement size limits with LRU eviction for large datasets (metadata), monitor cache memory usage, add metrics for hit/miss rates.

**WebSocket Manager Single Registry:**
- Problem: All subscriptions tracked in single ETS table without partitioning
- Files: `lib/hyperliquid/websocket/manager.ex` (setup at initialization)
- Cause: `list_subscriptions()` and other operations scan entire subscription table, becomes O(n) with thousands of subscriptions
- Improvement path: Partition subscriptions by user/topic, implement index on subscription_id for lookups, add query pagination, monitor table size and lookup times under load.

## Fragile Areas

**Endpoint Metadata Introspection via Function Exports:**
- Files: `lib/hyperliquid/api/endpoint.ex`, all endpoint modules
- Why fragile: Code relies on checking `function_exported?(endpoint_module, :__endpoint_info__, 0)` at compile/runtime. If this function is accidentally removed or renamed, endpoint discovery silently breaks.
- Safe modification: Add typespecs and docs for `__endpoint_info__/0`, add validation in tests that all endpoint modules export this function, consider using a behavior or protocol to enforce interface.
- Test coverage: No detected tests verifying endpoint metadata consistency across all 100+ endpoints.

**Cache Dependency on External API at Startup:**
- Files: `lib/hyperliquid/cache.ex` (lines 52-183)
- Why fragile: `init/0` makes hard HTTP dependency on Hyperliquid API being available. If API is down or slow, entire application startup blocks or fails.
- Safe modification: Make cache initialization async/fire-and-forget during application startup, return partial cache on partial failures, implement circuit breaker for API calls, add startup option to disable auto-init.
- Test coverage: No detected tests for partial failure scenarios (e.g., allMids succeeds but meta fails).

**Signer NIF Compilation Conditional:**
- Files: `lib/hyperliquid/signer.ex` (lines 2-10)
- Why fragile: Rustler NIF loading is conditional on file system (checks if `native/signer` exists). If directory structure changes, falls back to `:nif_not_loaded` errors at runtime with unclear messaging.
- Safe modification: Add explicit build-time check during mix compile, log informative message if NIF not available, provide Elixir-only fallbacks for non-cryptographic operations, document NIF requirement clearly.
- Test coverage: No detected tests for NIF loading failures.

**HTTP Transport Timeout Handling:**
- Files: `lib/hyperliquid/transport/http.ex` (line 30-31)
- Why fragile: Hardcoded 30-second timeout for all HTTP operations. No distinction between quick endpoints (allMids ~100ms) and slow endpoints (meta ~5s). Long-running requests have no retry logic.
- Safe modification: Make timeouts configurable per endpoint, implement exponential backoff retries for transient failures, add timeout context to error messages.
- Test coverage: No detected tests for timeout scenarios.

**Macro-Generated Function Signatures:**
- Files: `lib/hyperliquid/api/endpoint.ex` (extensive quote/unquote), `lib/hyperliquid/api/exchange.ex`, `lib/hyperliquid/api/info.ex`
- Why fragile: Large blocks of generated code (1300+ lines in endpoint.ex) make it difficult to understand actual function signatures. If parameter handling logic is wrong, affects all 100+ generated functions.
- Safe modification: Add integration tests that call generated functions with various parameter combinations, generate comprehensive documentation examples, add guards to catch parameter type errors early.
- Test coverage: Gap in testing parameter conversion (positional vs. keyword args).

## Scaling Limits

**ETS Table for Subscriptions (WebSocket Manager):**
- Current capacity: No explicit limits; holds one entry per active subscription
- Limit: Memory growth linear with subscription count, lookup time degrades as table grows, no automatic cleanup
- Scaling path: Implement subscription pruning for stale connections, partition subscriptions by topic/shard, migrate to Mnesia for distributed deployments if needed.

**Cachex In-Memory Storage:**
- Current capacity: Limited by available RAM; no TTL means unbounded growth for mutable data
- Limit: Large datasets (all_mids, metadata) can consume significant memory; no distribution across nodes
- Scaling path: Implement distributed cache (Redis/Memcached), add TTL and eviction policies, consider off-loading metadata to persistent store with lazy loading.

**HTTP Connection Pool:**
- Current capacity: HTTPoison default pool size (likely small)
- Limit: High-concurrency scenarios (many parallel requests) will exhaust pool and queue, leading to timeouts
- Scaling path: Configure HTTPoison pool size based on expected concurrency, implement request queuing with priority levels, add metrics to monitor pool utilization.

## Missing Critical Features

**No Rate Limit Handling:**
- Problem: Library doesn't track rate limit consumption or implement client-side rate limiting
- Files: Endpoints have `rate_limit_cost/0` defined but never used
- Blocks: Cannot reliably use library at scale without hitting Hyperliquid's 1200 req/min limit per IP
- Recommendation: Implement rate limit tracking per IP, add request queuing/throttling, expose rate limit window status, implement backoff strategies.

**No Batch Request Optimization:**
- Problem: Multiple independent endpoint calls execute sequentially instead of batching
- Files: All endpoint modules use individual request/response pattern
- Blocks: Cannot efficiently fetch multiple pieces of related data in single roundtrip
- Recommendation: Add batch request builder (combine multiple queries into single POST), optimize for endpoints that support batch parameters.

**No Request Retries or Circuit Breaking:**
- Problem: Transient failures immediately propagate to caller; no automatic retry logic
- Files: `lib/hyperliquid/transport/http.ex`, all endpoint modules
- Blocks: Network blips cause cascading failures in dependent code
- Recommendation: Implement exponential backoff retries for transient errors (timeouts, 5xx), add circuit breaker for repeatedly failing endpoints.

## Test Coverage Gaps

**Endpoint Macro Generation Logic Untested:**
- What's not tested: Generated function signatures, parameter passing (positional vs. keyword), delegation to underlying modules
- Files: `lib/hyperliquid/api/endpoint.ex` (1392 lines), `lib/hyperliquid/api/exchange.ex` (192 lines), `lib/hyperliquid/api/info.ex` (308 lines)
- Risk: Macro bugs affect all 100+ endpoints; difficult to catch without explicit integration tests
- Priority: **High** - Macro bugs are systematic and affect entire codebase

**Cache Initialization Failure Scenarios:**
- What's not tested: Partial API failures (e.g., meta succeeds but allMids fails), timeout handling, recovery from stale cache
- Files: `lib/hyperliquid/cache.ex` (800+ lines)
- Risk: Production startup issues if API is unavailable or slow
- Priority: **High** - Startup reliability critical

**WebSocket Connection Recovery:**
- What's not tested: Reconnection after network failure, message ordering during reconnection, subscription state consistency
- Files: `lib/hyperliquid/websocket/manager.ex` (900+ lines), `lib/hyperliquid/websocket/connection.ex` (472 lines)
- Risk: Data loss or duplicate messages on reconnection, subscriptions silently lost
- Priority: **High** - Data integrity critical for trading

**Error Handling Edge Cases:**
- What's not tested: Malformed API responses, partial JSON, timeout errors, rate limit errors
- Files: All transport/endpoint modules
- Risk: Unhandled exceptions, poor error messages for debugging
- Priority: **Medium** - Affects debuggability and reliability

**Parameter Validation:**
- What's not tested: Invalid parameter types, missing required fields, boundary values
- Files: All exchange endpoints (order, modify, cancel, etc.)
- Risk: Silent failures or confusing API error messages
- Priority: **Medium** - User experience and type safety

---

*Concerns audit: 2026-01-21*
