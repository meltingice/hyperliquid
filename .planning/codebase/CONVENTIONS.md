# Coding Conventions

**Analysis Date:** 2026-01-21

## Naming Patterns

**Files:**
- PascalCase for module files: `order.ex`, `all_mids.ex`, `clearinghouse_state.ex`
- Snake_case for file paths matching module hierarchy: `lib/hyperliquid/api/info/all_mids.ex`
- Test files use `_test.exs` suffix: `modify_test.exs`, `info_test.exs`, `signer_l1_test.exs`
- Module names are PascalCase: `Hyperliquid.Api.Info.AllMids`, `Hyperliquid.Storage.Writer`

**Functions:**
- Snake_case for all functions: `limit_order/4`, `trigger_order/6`, `market_order/4`
- Bang variants for error-raising versions: `request!/0`, `request!/1`, `fetch!/0`
- Prefixes for related functions: `build_cache_key/1`, `extract_records/1`, `cache_enabled?/0`
- Private functions use `defp` and prefix with `do_` for internal helpers: `do_flush/1`, `do_write_to_postgres/2`, `normalize_record/1`
- Predicate functions end with `?`: `storage_enabled?/0`, `cache_enabled?/0`, `function_exported?/3`

**Variables:**
- Snake_case throughout: `is_buy`, `limit_px`, `vault_address`, `floor_price`, `asset_positions`
- Short loop variables: `acc` for accumulator, `_mod` for unused values (prefix with underscore)
- Module aliases use short abbreviated names: `alias Hyperliquid.Utils.Format`
- Pattern variable names match module names: `%__MODULE__{}` for struct patterns

**Types:**
- Atom keys in maps (not strings): `:user`, `:insert_at`, `:conflict_target`
- Module names in types: `t()` for struct typedef, `MarginSummary.t()` for embedded schemas
- Type specs use `term()` for generic types when specific type unknown

**Module Attributes:**
- `@moduledoc` strings at module top with description and usage examples
- `@spec` annotations for all public functions with clear return types
- `@primary_key false` for embedded Ecto schemas without primary keys
- `@impl true` annotations for GenServer callbacks and behavior implementations
- `@type t :: %__MODULE__{...}` for struct type definitions
- `@doc` strings for all public functions with parameter descriptions and examples

## Code Style

**Formatting:**
- Elixir formatter is configured via `.formatter.exs`
- Inputs: `{mix,.formatter}.exs`, `{config,lib,test}/**/*.{ex,exs}`
- Automatic formatting enforced: 2-space indentation (Elixir standard)
- Run with: `mix format`

**Linting:**
- Credo is configured for development/test environments (`credo ~> 1.7`)
- Credo checks code style, complexity, and convention violations
- Run with: `mix credo`

**Indentation and Spacing:**
- 2-space indentation (Elixir standard, enforced by formatter)
- Blank line before function definitions (section headers use `# ============ Section Name ============`)
- Long parameter lists aligned across multiple lines:
  ```elixir
  def limit_order(
    coin,
    is_buy,
    limit_px,
    sz,
    opts \\ []
  ) do
  ```
- Pipeline operators `|>` used for multi-step transformations
- Comments use `#` with space: `# This is a comment`

## Import Organization

**Order:**
1. Built-in/standard modules (minimal, usually via macros)
2. OTP/Phoenix modules (`use`, `import`)
3. Project internal modules (`alias`)

**Pattern from `Hyperliquid.Api.Info.ClearinghouseState`:**
```elixir
use Hyperliquid.Api.Endpoint, [
  type: :info,
  request_type: "clearinghouseState",
  params: [:user],
  ...
]
```

**Pattern from `Hyperliquid.Api.Exchange.Order`:**
```elixir
alias Hyperliquid.{Cache, Config, Signer, Utils}
alias Hyperliquid.Utils.Format
alias Hyperliquid.Transport.Http
```

**Path Aliases:**
- No custom import aliases defined in `.formatter.exs`
- Uses explicit module paths throughout
- Compact alias form: `alias Hyperliquid.{Cache, Config, Signer}` for grouped imports

## Error Handling

**Patterns:**
1. **Result tuples** for public APIs: `{:ok, result}` or `{:error, reason}`
   - All endpoint `request/N` functions return `{:ok, struct()} | {:error, term()}`
   - All fetch functions return `{:ok, struct()} | {:error, term()}`

2. **Bang variants** for error-raising: `{:error, reason}` raises as an exception
   - `request!/0`, `request!/1` raise on error
   - `fetch!/0`, `fetch!/1` raise on error
   - Pattern from `Hyperliquid.Api.Info.AllMids`:
     ```elixir
     @spec request() :: {:ok, struct()} | {:error, term()}
     def request() do
       ...
     end

     @spec request!() :: struct()
     def request!() do
       ...
     end
     ```

3. **`with` statements** for chained operations with error propagation
   - Used in `Order.limit_order/5`:
     ```elixir
     with {:ok, asset, sz_decimals, is_spot} <- resolve_coin(coin) do
       # proceed with resolved values
     end
     ```

4. **`case` statements** for pattern matching on data structures
   - Used in `Storage.Writer.normalize_record/1`:
     ```elixir
     case leverage do
       %{"type" => "isolated", "value" => value, ...} -> []
       %{"type" => "cross", ...} -> []
       _ -> [leverage: "error message"]
     end
     ```

5. **`rescue` blocks** for exception handling in critical paths
   - Used in `Storage.Writer.write_to_single_table/3`:
     ```elixir
     try do
       transform_fn.(records)
     rescue
       error ->
         Logger.error("[Storage.Writer] Transform failed: #{Exception.message(error)}")
         reraise error, __STACKTRACE__
     end
     ```

6. **Guard clauses** for parameter validation
   - `when is_binary(key)`, `when is_map(record)`, `when is_list(data)`
   - Used throughout `Hyperliquid.Api.Exchange.Order` and `Storage.Writer`

7. **Logger for diagnostics:**
   - `Logger.info/1` for normal flow events: `"[Storage.Writer] Wrote #{count} records"`
   - `Logger.error/1` for exceptions: `"[Storage.Writer] Postgres insert failed for #{table}"`
   - `Logger.debug/1` for conditional flow: `"[Storage.Writer] Skipping Postgres write"`
   - Format: `"[Module] Short message with #{interpolation}"`

## Logging

**Framework:** Elixir built-in `Logger` module

**Patterns:**
- Scoped messages with module prefix: `[Storage.Writer]`, `[Api.Exchange]`
- Include context in messages: table names, module names, count of operations
- Error logs include `Exception.message(error)` for debugging
- Debug logs for optional/conditional operations

**Examples from codebase:**
```elixir
Logger.info("[Storage.Writer] Wrote #{total_count} total records across #{length(table_configs)} tables")
Logger.error("[Storage.Writer] Failed to write batch for #{inspect(module)}: #{Exception.message(error)}")
Logger.debug("[Storage.Writer] Skipping Postgres write - database not enabled")
```

## Comments

**When to Comment:**
- Section headers separating logical groups:
  ```elixir
  # ===================== Client API =====================
  # ===================== Server Callbacks =====================
  # ===================== Private Functions =====================
  ```
- Non-obvious algorithmic choices or workarounds
- Complex nested schemas with embedded types
- Integration with external systems/APIs

**JSDoc/ExDoc Style:**
- All public functions have `@doc` blocks with:
  - Single-line summary
  - ## Parameters section (if applicable)
  - ## Returns section (if applicable)
  - ## Examples section with iex examples
  - ## Options section (for keyword arguments)

**Example from `Hyperliquid.Api.Info.AllMids`:**
```elixir
@doc """
Get the mid price for a specific coin.

## Example

    iex> get_mid(%AllMids{mids: %{"BTC" => "43250.5"}}, "BTC")
    {:ok, "43250.5"}

    iex> get_mid(%AllMids{mids: %{"BTC" => "43250.5"}}, "DOGE")
    {:error, :not_found}
"""
@spec get_mid(t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
def get_mid(%__MODULE__{mids: mids}, coin) when is_binary(coin) do
  case Map.fetch(mids, coin) do
    {:ok, price} -> {:ok, price}
    :error -> {:error, :not_found}
  end
end
```

## Function Design

**Size:** Functions typically 5-30 lines
- Private helper functions are 1-10 lines
- Public API functions handle parameter validation and delegation
- Larger functions use `|>` pipeline for readability

**Parameters:**
- Required parameters come first
- Optional parameters use `\\` default value syntax: `opts \\ []`
- Guard clauses specify parameter types: `when is_binary(coin)`
- Variadic patterns like `param_vars = for param <- params, do: Macro.var(param, nil)`

**Return Values:**
- All public functions return tuples: `{:ok, value}` or `{:error, reason}`
- Bang variants raise exceptions instead of returning error tuples
- Spec annotations document exact return types:
  ```elixir
  @spec request(keyword()) :: {:ok, struct()} | {:error, term()}
  def request(opts \\ []) do
    ...
  end
  ```

## Module Design

**Exports:**
- All public functions documented with `@doc` and `@spec`
- Private functions use `defp` and have explanatory comments if non-obvious
- No module constants exposed; use module attributes or configuration
- Public helper functions like `get_mid/2`, `get_coins/1` are kept small and focused

**Barrel Files:**
- `Hyperliquid.Api.Info` and `Hyperliquid.Api.Exchange` act as convenience wrappers
- Generated at compile-time using macros that iterate over endpoint modules
- Delegate to underlying endpoint modules without adding logic
- Each endpoint is self-contained in its own module

**Module Organization Pattern:**
```elixir
defmodule Hyperliquid.Api.Info.SomeEndpoint do
  # ===================== Configuration =====================
  use Hyperliquid.Api.Endpoint, [...]

  @type t :: %__MODULE__{...}
  embedded_schema do
    # fields
  end

  # ===================== Changeset =====================
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(...) do
    ...
  end

  # ===================== Helpers =====================
  @doc "Helper function"
  @spec helper() :: result()
  def helper() do
    ...
  end

  # ===================== Private Functions =====================
  defp private_helper() do
    ...
  end
end
```

---

*Convention analysis: 2026-01-21*
