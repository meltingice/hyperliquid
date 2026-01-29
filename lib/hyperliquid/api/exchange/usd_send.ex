defmodule Hyperliquid.Api.Exchange.UsdSend do
  @moduledoc """
  Send USD to another address.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer, Utils}
  alias Hyperliquid.Api.Exchange.KeyUtils
  alias Hyperliquid.Transport.Http

  @doc """
  Send USD to another address.

  ## Parameters
    - `destination`: Destination address
    - `amount`: Amount to send (string or number, e.g. 1 = $1)
    - `opts`: Optional parameters

  ## Options
    - `:private_key` - Private key for signing (falls back to config)
    - `:expected_address` - When provided, validates the private key derives to this address

  ## Returns
    - `{:ok, response}` - Transfer result
    - `{:error, term()}` - Error details

  ## Examples

      {:ok, result} = UsdSend.request("0x...", "100.0")
      {:ok, result} = UsdSend.request("0x...", "100.0", private_key: "abc...")

  ## Breaking Change (v0.2.0)
  `private_key` was previously the first positional argument. It is now
  an option in the opts keyword list (`:private_key`).
  """
  def request(destination, amount, opts \\ []) do
    private_key = KeyUtils.resolve_and_validate!(opts)
    amount = to_string(amount)
    time = generate_nonce()
    is_mainnet = Config.mainnet?()

    sig = Signer.sign_usd_send(private_key, destination, amount, time, is_mainnet)

    # IMPORTANT: Use OrderedObject for correct field order in hash calculation
    # Field order: type, signatureChainId, hyperliquidChain, destination, amount, time
    action =
      Jason.OrderedObject.new([
        {:type, "usdSend"},
        {:signatureChainId, signature_chain_id(is_mainnet)},
        {:hyperliquidChain, if(is_mainnet, do: "Mainnet", else: "Testnet")},
        {:destination, destination},
        {:amount, amount},
        {:time, time}
      ])

    signature = %{r: sig["r"], s: sig["s"], v: sig["v"]}

    Http.user_signed_request(action, signature, time, opts)
  end

  # Hyperliquid uses signatureChainId 42161 (Arbitrum One) for BOTH mainnet and testnet.
  defp signature_chain_id(_is_mainnet), do: Utils.from_int(42_161)

  defp generate_nonce do
    System.system_time(:millisecond)
  end
end
