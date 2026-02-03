# Exchange API

The Exchange API handles trading operations and account management. All modules are under `Hyperliquid.Api.Exchange.*`.

All exchange actions require a private key for signing. The key defaults to the one in your config, or can be passed per-request via the `:private_key` option.

## Signing Modes

- **`:exchange` signing** - Orders, cancels, leverage changes. Can use an agent key approved via `ApproveAgent`.
- **`:l1` signing** - Transfers, withdrawals, vault operations, sub-account creation. Requires your main private key.

## Order Management

| Module | Description |
|--------|-------------|
| `Order` | Place orders (limit, market, trigger) |
| `Modify` | Modify existing orders |
| `BatchModify` | Batch order modifications |
| `Cancel` | Cancel orders by asset + OID |
| `CancelByCloid` | Cancel by client order ID |

### Order Helpers

```elixir
alias Hyperliquid.Api.Exchange.Order

# Limit order
{:ok, result} = Order.place_limit("BTC", true, "43000.0", "0.1")

# Market order
{:ok, result} = Order.place_market("ETH", false, "1.5")

# Trigger (stop) order
{:ok, result} = Order.place_trigger("BTC", true, "42000.0", "0.1",
  trigger_px: "41500.0", tp_sl: "sl")

# Build order structs manually
order = Order.limit_order("BTC", true, "43000.0", "0.1")
{:ok, result} = Order.place(order)

# Batch orders
{:ok, result} = Order.place_batch([order1, order2], "na")
```

## Account Operations

| Module | Signing | Description |
|--------|---------|-------------|
| `UpdateLeverage` | `:exchange` | Change position leverage |
| `UpdateIsolatedMargin` | `:exchange` | Modify isolated margin |
| `UsdClassTransfer` | `:l1` | Transfer USD between accounts |
| `Withdraw3` | `:l1` | Withdraw to L1 |
| `SpotSend` | `:l1` | Send spot tokens |
| `CreateSubAccount` | `:l1` | Create sub-accounts |
| `SubAccountTransfer` | `:l1` | Transfer between sub-accounts |
| `ApproveAgent` | `:l1` | Approve agent key for trading |
| `ApproveBuilderFee` | `:l1` | Approve builder fee |

## Vault Operations

| Module | Signing | Description |
|--------|---------|-------------|
| `CreateVault` | `:l1` | Create a new vault |
| `VaultTransfer` | `:l1` | Vault deposits/withdrawals |

## Per-Request Options

```elixir
# Override private key
Order.place_limit("BTC", true, "43000.0", "0.1", private_key: agent_key)

# Vault operations
Order.place_limit("BTC", true, "43000.0", "0.1", vault_address: "0x...")
```

For the complete list of 38 Exchange endpoints, see the [HexDocs](https://hexdocs.pm/hyperliquid).
