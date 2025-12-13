# Hyperliquid Signer NIF

Rustler NIF that exposes Hyperliquid signing primitives to Elixir for low-latency request signing.

This crate depends on the local `hyperliquid_rust_sdk` and mirrors its signing logic exactly.

## What it provides

- compute_connection_id/3 — Compute the action connection hash used for L1 action signatures
- sign_exchange_action/5 — Sign any exchange action (orders, cancels, modifies, etc.)
- sign_usd_send/5 — Sign EIP-712 UsdSend
- sign_withdraw3/5 — Sign EIP-712 Withdraw
- sign_spot_send/6 — Sign EIP-712 SpotSend
- sign_approve_builder_fee/5 — Sign EIP-712 ApproveBuilderFee
- sign_approve_agent/6 — Sign EIP-712 ApproveAgent

All functions return an Elixir map: `%{signature: "0x...", r: "0x...", s: "0x...", v: 27|28, connection_id?: "0x..."}`

## Build

From this directory:

```bash
cargo build --release
```

Or let Rustler build it when compiling your Elixir project.

## Integrating into an Elixir project

Add `:rustler` to your mix deps:

```elixir
# mix.exs
{:rustler, "~> 0.33"}
```

Create a small wrapper module and point Rustler to this crate path:

```elixir
# lib/hyperliquid/signer.ex
defmodule Hyperliquid.Signer do
  use Rustler,
    otp_app: :your_app,
    crate: "hyperliquid_signer_nif",
    # Adjust path as needed relative to your mix project root
    path: Path.expand("../signer_nif", __DIR__)

  # Fallbacks while NIF loads
  def compute_connection_id(_action_json, _nonce, _vault_address), do: :erlang.nif_error(:nif_not_loaded)
  def sign_exchange_action(_pk, _action_json, _nonce, _is_mainnet, _vault_addr), do: :erlang.nif_error(:nif_not_loaded)
  def sign_usd_send(_pk, _dest, _amount, _time, _is_mainnet), do: :erlang.nif_error(:nif_not_loaded)
  def sign_withdraw3(_pk, _dest, _amount, _time, _is_mainnet), do: :erlang.nif_error(:nif_not_loaded)
  def sign_spot_send(_pk, _dest, _token, _amount, _time, _is_mainnet), do: :erlang.nif_error(:nif_not_loaded)
  def sign_approve_builder_fee(_pk, _builder, _max_fee_rate, _nonce, _is_mainnet), do: :erlang.nif_error(:nif_not_loaded)
  def sign_approve_agent(_pk, _agent_addr, _agent_name, _nonce, _is_mainnet), do: :erlang.nif_error(:nif_not_loaded)
end
```

Then call the NIFs directly from your request code.

## Example: place order signing

Build the action JSON exactly like the SDK serializes it. Use short keys in `orders`: `a` (asset), `b` (isBuy), `p` (price), `s` (size), `r` (reduceOnly), `t` (type), `c` (optional cloid).

```elixir
nonce = System.system_time(:millisecond)
asset_index = 1 # or 10000 + spot_index for spot pairs
order = %{
  a: asset_index,
  b: true,
  p: "2000.0",
  s: "1.5",
  r: false,
  t: %{limit: %{tif: "Ioc"}}
}
action = %{type: "order", orders: [order], grouping: "na"}
action_json = Jason.encode!(action)

vault_addr = nil # or "0x..." if signing for vault/subaccount
sig = Hyperliquid.Signer.sign_exchange_action(privkey_hex, action_json, nonce, true, vault_addr)
# => %{signature: "0x..", r: "0x..", s: "0x..", v: 27, connection_id: "0x.."}

# Use the signature in your HTTP POST body to /exchange along with the action and nonce.
```

## Notes on hashing and signatures

- L1 actions (orders/cancels/modifies/etc) are signed over `connectionId = keccak256(rmp(action) || nonce_be8 || vault_flag || vault_address?)`.
  - `vault_flag` is `0x01` if present, otherwise `0x00`.
  - The EIP-712 domain for the L1 signature is `name: "Exchange", version: "1", chainId: 1337, verifyingContract: 0x0`.
  - `source` in the typed struct is "a" for mainnet, "b" for testnet.
- Typed actions (e.g., UsdSend, Withdraw3, SpotSend, ApproveBuilderFee, ApproveAgent) use domain `name: "HyperliquidSignTransaction", version: "1", chainId: 421614` with their respective struct encodings exactly as in the Rust SDK.
- Returned `v` is `27/28` compatible with the exchange API.

## Performance tips

- Reuse the same NIF-loaded module and keep the process hot.
- Avoid re-encoding large action bodies repeatedly; compute once per request.
- For higher throughput, batch orders in a single action like the SDK’s `bulk_order` does.

## Caveats

- `expiresAfter` is not currently included by the Rust SDK; if you need it, we can extend the NIF and SDK once the precise signing rules are confirmed from the Python SDK.
