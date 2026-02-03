# RPC Transport

Make JSON-RPC calls to the Hyperliquid EVM via `Hyperliquid.Transport.Rpc`.

## Single Calls

```elixir
alias Hyperliquid.Transport.Rpc

{:ok, block_number} = Rpc.call("eth_blockNumber", [])
{:ok, balance} = Rpc.call("eth_getBalance", ["0x1234...", "latest"])
```

## Batch Calls

```elixir
{:ok, [block, chain_id]} = Rpc.batch([
  {"eth_blockNumber", []},
  {"eth_chainId", []}
])
```

## Options

```elixir
# Use a named RPC endpoint
Rpc.call("eth_blockNumber", [], rpc_name: :alchemy)

# Override URL directly
Rpc.call("eth_blockNumber", [], rpc_url: "https://custom-rpc.example.com")

# Custom timeout
Rpc.call("eth_blockNumber", [], timeout: 10_000)
```

## Named RPC Registry

Configure multiple RPC endpoints in your config:

```elixir
config :hyperliquid,
  named_rpcs: %{
    alchemy: "https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY",
    quicknode: "https://your-endpoint.quiknode.pro/YOUR_KEY",
    local: "http://localhost:8545"
  }
```

## Namespaced Modules

Convenience modules for common RPC methods:

- `Hyperliquid.Rpc.Eth` - `eth_*` methods
- `Hyperliquid.Rpc.Net` - `net_*` methods
- `Hyperliquid.Rpc.Web3` - `web3_*` methods
- `Hyperliquid.Rpc.Custom` - Hyperliquid-specific RPC methods
