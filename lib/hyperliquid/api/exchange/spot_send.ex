defmodule Hyperliquid.Api.Exchange.SpotSend do
  @moduledoc """
  Send spot tokens to another address.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer, Utils}
  alias Hyperliquid.Transport.Http

  @doc """
  Send spot tokens to another address.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `destination`: Destination address
    - `token`: Token identifier (e.g., "USDC:0xeb62eee3685fc4c43992febcd9e75443")
    - `amount`: Amount to send (string or number)
    - `opts`: Optional parameters

  ## Returns
    - `{:ok, response}` - Transfer result
    - `{:error, term()}` - Error details

  ## Examples

      {:ok, result} = SpotSend.request(private_key, "0x...", "HYPE:0x...", "10.0")
  """
  def request(private_key, destination, token, amount, opts \\ []) do
    amount = to_string(amount)
    time = generate_nonce()
    is_mainnet = Config.mainnet?()

    sig = Signer.sign_spot_send(private_key, destination, token, amount, time, is_mainnet)

    # IMPORTANT: Use OrderedObject for correct field order in hash calculation
    # Field order: type, signatureChainId, hyperliquidChain, destination, token, amount, time
    action =
      Jason.OrderedObject.new([
        {:type, "spotSend"},
        {:signatureChainId, signature_chain_id(is_mainnet)},
        {:hyperliquidChain, if(is_mainnet, do: "Mainnet", else: "Testnet")},
        {:destination, destination},
        {:token, token},
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
