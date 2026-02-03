# Error Handling

All API calls return `{:ok, result}` or `{:error, %Hyperliquid.Error{}}`.

## Error Types

| Type | Source |
|------|--------|
| `:jsonrpc` | JSON-RPC error (code + message + data) |
| `:http` | HTTP error (status code + message) |
| `:transport` | Network/connection error (reason) |
| `:unknown` | Unclassified error |

## Error Structure

```elixir
%Hyperliquid.Error{
  message: "Rate limited",
  code: -32000,           # JSON-RPC code (if applicable)
  data: nil,              # Additional error data
  status_code: 429,       # HTTP status (if applicable)
  reason: nil,            # Transport error reason
  response: raw_response, # Raw response body
  type: :http             # Error classification
}
```

## Pattern Matching

```elixir
case AllMids.request() do
  {:ok, mids} ->
    process(mids)

  {:error, %Hyperliquid.Error{type: :http, status_code: 429}} ->
    Process.sleep(1000)
    retry()

  {:error, %Hyperliquid.Error{type: :transport}} ->
    Logger.warning("Network error, retrying...")
    retry()

  {:error, error} ->
    Logger.error("API error: #{error.message}")
end
```

## Bang Variants

Use `request!/N` to raise on error instead:

```elixir
# Raises Hyperliquid.Error on failure
mids = AllMids.request!()
```
