defmodule Hyperliquid.Api.Exchange.UsdSend do
  @moduledoc """
  Send USD to another address.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer, Utils}
  alias Hyperliquid.Transport.Http

  @doc """
  Send USD to another address.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `destination`: Destination address
    - `amount`: Amount to send as string (1 = $1)
    - `opts`: Optional parameters

  ## Returns
    - `{:ok, response}` - Transfer result
    - `{:error, term()}` - Error details

  ## Examples

      {:ok, result} = UsdSend.request(private_key, "0x...", "100.0")
  """
  def request(private_key, destination, amount, opts \\ []) do
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

  defp signature_chain_id(true), do: Utils.from_int(42_161)
  defp signature_chain_id(false), do: Utils.from_int(421_614)

  defp generate_nonce do
    System.system_time(:millisecond)
  end
end
