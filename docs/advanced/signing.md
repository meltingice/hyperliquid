# Signing & Authentication

All exchange actions are cryptographically signed using EIP-712 typed data, implemented as a Rust NIF for performance.

## Signing Modes

### Exchange Signing

Used for trading operations (orders, cancels, leverage). These can be delegated to an **agent key**.

```elixir
# Uses the private key from config
Order.place_limit("BTC", true, "43000.0", "0.1")

# Override per-request
Order.place_limit("BTC", true, "43000.0", "0.1", private_key: agent_key)
```

### L1 Signing

Used for account-level operations (transfers, withdrawals, sub-accounts). Requires the **main private key**.

```elixir
UsdClassTransfer.request(params, private_key: "MAIN_KEY")
Withdraw3.request(params, private_key: "MAIN_KEY")
```

## Agent Keys

For trading bots, approve an agent key to avoid exposing your main key:

```elixir
# 1. Approve agent (one-time, requires main key)
ApproveAgent.request(%{
  agent_address: "0xAgentAddress",
  agent_name: "my-bot"
}, private_key: "MAIN_KEY")

# 2. Configure agent key for daily use
config :hyperliquid, private_key: "AGENT_KEY"
```

## Signer Functions

The `Hyperliquid.Signer` module exposes Rust NIFs:

| Function | Purpose |
|----------|---------|
| `sign_exchange_action_ex/6` | Sign exchange actions |
| `sign_l1_action/3` | Sign L1 actions |
| `sign_usd_send/5` | Sign USD transfers |
| `sign_withdraw3/5` | Sign withdrawals |
| `sign_spot_send/6` | Sign spot transfers |
| `sign_approve_agent/5` | Sign agent approval |
| `derive_address/1` | Derive address from private key |
| `to_checksum_address/1` | EIP-55 checksum |

## Address Derivation

```elixir
address = Hyperliquid.Signer.derive_address("0xprivatekey...")
# => "0x1234...abcd"

checksummed = Hyperliquid.Signer.to_checksum_address(address)
# => "0x1234...AbCd"
```
