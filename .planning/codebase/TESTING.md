# Testing Patterns

**Analysis Date:** 2026-01-21

## Test Framework

**Runner:**
- ExUnit (Elixir built-in testing framework)
- No external version specified (built into Elixir)
- Config: `test/test_helper.exs`

**Assertion Library:**
- ExUnit built-in assertions: `assert`, `assert_raise`, `assert_receive`
- Pattern matching in assertions: `assert {:ok, %{...}} = result`

**Run Commands:**
```bash
mix test                          # Run all tests
mix test test/path/to/test.exs   # Run specific test file
mix test --watch                 # Watch mode (if file_system configured)
mix test --include integration   # Run tests tagged with :integration
```

**Test Setup:**
- Database setup/teardown: `mix test` alias configured in `mix.exs` runs `ecto.create --quiet`, `ecto.migrate --quiet` before tests
- Application startup: `test/test_helper.exs` calls `Application.ensure_all_started(:bypass)` and `ExUnit.start()`

## Test File Organization

**Location:**
- Co-located with source code: tests live in `test/` directory mirroring `lib/` structure
- Pattern: `test/api/exchange/modify_test.exs` for `lib/hyperliquid/api/exchange/modify.ex`

**Naming:**
- Module name appends `Test`: `Hyperliquid.Api.Exchange.ModifyTest`
- File name appends `_test.exs`: `modify_test.exs`

**Structure:**
```
test/
├── api/
│   ├── exchange/
│   │   ├── modify_test.exs
│   │   ├── batch_modify_test.exs
│   │   └── ...
│   └── info_test.exs
├── storage/
│   └── writer_test.exs
├── rpc/
│   └── evm_test.exs
└── test_helper.exs
```

## Test Structure

**Suite Organization:**

From `Hyperliquid.Api.Exchange.ModifyTest`:
```elixir
defmodule Hyperliquid.Api.Exchange.ModifyTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.{Modify, Order}
  alias Hyperliquid.Signer

  @priv_key "0x..."

  describe "modify/4" do
    test "creates correct action structure for limit order" do
      # Test implementation
    end

    test "creates correct action structure for trigger order" do
      # Test implementation
    end
  end
end
```

**Patterns:**
- `describe/2` blocks group related tests by function/feature
- `test/2` individual test cases with descriptive names
- Setup using `setup/1` block (context available to all tests) or per-test setup
- Aliases at top: `alias Hyperliquid.Api.Info`, `alias Hyperliquid.Signer`
- Module attributes for shared test data: `@priv_key "0x..."`, `@action %{...}`, `@nonce 1_234_567_890`

**Async Configuration:**
- `async: true` for tests with no side effects or shared state (unit tests)
  - Example: `Hyperliquid.Api.Exchange.ModifyTest`, `Hyperliquid.SignerL1Test`
- `async: false` for tests with database operations or side effects
  - Example: `Hyperliquid.Api.InfoTest` (uses Bypass), `Hyperliquid.Storage.WriterTest` (creates tables)

**Setup/Teardown Pattern:**

From `Hyperliquid.Api.InfoTest`:
```elixir
setup do
  bypass = Bypass.open()
  Application.put_env(:hyperliquid, :http_url, "http://localhost:#{bypass.port}")
  Application.put_env(:hyperliquid, :rpc_url, "http://localhost:#{bypass.port}")
  {:ok, bypass: bypass}
end
```

From `Hyperliquid.Storage.WriterTest`:
```elixir
setup do
  case GenServer.whereis(Hyperliquid.Storage.Writer) do
    nil -> start_supervised!(Hyperliquid.Storage.Writer)
    _pid -> :ok
  end

  Ecto.Adapters.SQL.query!(
    Repo,
    "CREATE TABLE IF NOT EXISTS writer_test_single (...)"
  )

  on_exit(fn ->
    Ecto.Adapters.SQL.query!(Repo, "DROP TABLE IF EXISTS writer_test_single")
  end)
end
```

## Test Structure

**Common Assertion Patterns:**

1. **Result tuple assertions:**
```elixir
assert {:ok, %{status: "ok"}} = Info.all_mids()
assert {:ok, result} = Info.clearinghouse_state("0x...")
```

2. **Error assertions:**
```elixir
assert_raise ArgumentError, ~r/required param user is nil/, fn ->
  Info.clearinghouse_state(nil)
end
```

3. **Exact value matching:**
```elixir
assert hash == "0x25367e0dba84351148288c2233cd6130ed6cec5967ded0c0b7334f36f957cc90"
assert sig["v"] == 28
```

4. **Pattern matching assertions:**
```elixir
assert %{r: _, s: _, v: _} = signature
assert %{"status" => "ok", "response" => %{"type" => "allMids"}} = _
```

## Mocking

**Framework:** Bypass for HTTP mocking
- Dependency: `{:bypass, "~> 2.1", only: :test}`
- Used to mock external HTTP endpoints in tests

**Patterns:**

From `Hyperliquid.Api.InfoTest`:
```elixir
test "all_mids posts to /info with type=allMids", %{bypass: bypass} do
  Bypass.expect(bypass, "POST", "/info", fn conn ->
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    payload = Jason.decode!(body)
    assert payload["type"] == "allMids"

    resp = %{
      "status" => "ok",
      "response" => %{
        "type" => "allMids",
        "data" => %{"BTC" => "50000.0", "ETH" => "2500.0"}
      }
    }

    Plug.Conn.put_resp_header(conn, "content-type", "application/json")
    |> Plug.Conn.resp(200, Jason.encode!(resp))
  end)

  assert {:ok, _} = Info.all_mids()
end
```

**What to Mock:**
- External HTTP APIs (via Bypass)
- Database operations (if testing business logic without DB)
- GenServer interactions (via mocks, fixtures)

**What NOT to Mock:**
- Ecto changesets and validations (test actual behavior)
- Core Elixir library functions
- Signing operations (test actual crypto, use known keys)

## Fixtures and Factories

**Test Data:**

From `Hyperliquid.Storage.WriterTest`:
```elixir
defmodule SingleTableMock do
  def __postgres_tables__ do
    [
      %{
        table: "writer_test_single",
        extract: :records,
        conflict_target: :record_id,
        on_conflict: {:replace, [:value, :updated_at]},
        transform: nil,
        fields: nil
      }
    ]
  end

  def storage_enabled?, do: true
  def postgres_enabled?, do: true
  def cache_enabled?, do: false
end
```

**Location:**
- Mock modules defined within test files themselves (no separate factory directory)
- Inline dummy structs and data: `defmodule DummyStruct do defstruct [:field1, :field2] end`
- Shared test constants as module attributes:
  ```elixir
  @priv_key "0x822e9959e022b78423eb653a62ea0020cd283e71a2a8133a6ff2aeffaf373cff"
  @action %{type: "order", orders: [...], grouping: "na"}
  @nonce 1_234_567_890
  @vault "0x1234567890123456789012345678901234567890"
  ```

## Coverage

**Requirements:** No coverage metrics enforced in configuration
- Credo and ExUnit configured but no coverage tool (e.g., ExCoveralls) configured
- Coverage is informal; developers encouraged to test thoroughly

**View Coverage:**
```bash
# No built-in command; coverage tool would need to be added
# Would require ExCoveralls or similar external tool
```

## Test Types

**Unit Tests:**
- Scope: Single module/function without external dependencies
- Approach: Test in isolation using mocks for external systems
- Example: `Hyperliquid.SignerL1Test` - tests cryptographic signing functions with known inputs/outputs
- Run with: `mix test test/signer_l1_test.exs`

**Integration Tests:**
- Scope: Multiple modules working together, may include database/HTTP calls
- Approach: Use Bypass for HTTP, test actual Ecto schemas and queries
- Example: `Hyperliquid.Api.InfoTest` - tests HTTP call flow with mocked endpoints
- Example: `Hyperliquid.Storage.WriterTest` - tests GenServer + Postgres interaction
- Marked as `async: false` because of side effects

**E2E Tests:**
- Framework: Not used (no external E2E test framework configured)
- Manual testing would be done against staging/production endpoints
- Could be added with Playwright/Cypress for full integration testing

## Common Patterns

**Async Testing:**

From `Hyperliquid.SignerL1Test`:
```elixir
defmodule Hyperliquid.SignerL1Test do
  use ExUnit.Case, async: true

  defp hex32(<<"0x", rest::binary>>) do
    "0x" <> String.pad_leading(rest, 64, "0")
  end

  defp sign(is_mainnet?, vault, expires) do
    action_json = Jason.encode!(@action)
    Signer.sign_exchange_action_ex(@priv_key, action_json, @nonce, is_mainnet?, vault, expires)
    |> Map.take(["r", "s", "v"])
  end

  test "mainnet: without vaultAddress + expiresAfter" do
    sig = sign(true, nil, nil)
    assert hex32(sig["r"]) == "0x61078d8ffa3cb591de045438a1ae2ed299b271891d1943a33901e7cfb3a31ed8"
  end
end
```

**Patterns:**
- Helper functions `defp` for shared test logic
- Private functions used across multiple tests
- No test isolation issues since tests are `async: true`

**Error Testing:**

From `Hyperliquid.Api.InfoTest`:
```elixir
test "clearinghouse_state requires user param", _ctx do
  # The function should raise before any HTTP request is made, so no Bypass expectation here.
  assert_raise ArgumentError, ~r/required param user is nil/, fn ->
    Info.clearinghouse_state(nil)
  end
end
```

**Patterns:**
- `assert_raise/3` to test exceptions
- Regex matching on error messages: `~r/pattern/`
- Anonymous function passed to test error condition

**Database Testing:**

From `Hyperliquid.Storage.WriterTest`:
```elixir
test "write_to_single_table with extraction and transformation", %{} do
  events_data = [
    %{
      "id" => 1,
      "primary" => %{"name" => "Test"},
      "secondary" => [%{"key" => "a", "value" => 100}]
    }
  ]

  {:ok, count} = Writer.store_sync(MultiTableMock, events_data)
  assert count > 0

  # Verify data was written
  query = from r in "writer_test_primary", select: r.name
  assert Repo.all(query) == ["Test"]
end
```

**Patterns:**
- Setup creates actual database tables for integration testing
- Tests use `Repo.all/1` with `from/1` queries to verify writes
- Cleanup with `on_exit/1` callback to drop tables
- Both sync and async operations tested:
  ```elixir
  {:ok, count} = Writer.store_sync(module, event_data)  # Blocking
  :ok = Writer.store_async(module, event_data)          # Non-blocking
  ```

## Test Organization Best Practices

**File Structure:**
- One test module per implementation module
- Descriptive test names explaining what is being tested, not just "test_x"
- Group related tests with `describe/2` blocks

**Naming Convention:**
- Test names should be grammatically readable: `"creates correct action structure for limit order"`
- Avoid test names starting with "test_", rely on `test/2` macro

**Isolation:**
- Use `setup/1` for test fixtures and configuration
- Use `on_exit/1` for cleanup operations
- Mark tests `async: true` only when safe

---

*Testing analysis: 2026-01-21*
