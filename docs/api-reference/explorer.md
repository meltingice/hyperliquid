# Explorer API

Query the Hyperliquid block explorer. All modules are under `Hyperliquid.Api.Explorer.*`.

## Endpoints

| Module | Parameters | Description |
|--------|-----------|-------------|
| `BlockDetails` | `block_height` | Block information by height |
| `TxDetails` | `tx_hash` | Transaction details by hash |
| `UserDetails` | `user_address` | User information |

## Usage

```elixir
alias Hyperliquid.Api.Explorer.{BlockDetails, TxDetails, UserDetails}

{:ok, block} = BlockDetails.request(12345)
{:ok, tx} = TxDetails.request("0xabcdef...")
{:ok, user} = UserDetails.request("0x1234...")
```
