defmodule Hyperliquid.Api.Exchange.Withdraw3 do
  @moduledoc """
  Initiate a withdrawal request.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer, Utils}
  alias Hyperliquid.Transport.Http

  @doc """
  Initiate a withdrawal request.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `destination`: Destination address
    - `amount`: Amount to withdraw (string or number, e.g. 1 = $1)
    - `opts`: Optional parameters

  ## Returns
    - `{:ok, response}` - Withdrawal result
    - `{:error, term()}` - Error details

  ## Examples

      {:ok, result} = Withdraw3.request(private_key, "0x...", "100.0")
  """
  def request(private_key, destination, amount, opts \\ []) do
    amount = to_string(amount)
    time = generate_nonce()
    is_mainnet = Config.mainnet?()

    sig = Signer.sign_withdraw3(private_key, destination, amount, time, is_mainnet)

    action = %{
      type: "withdraw3",
      hyperliquidChain: if(is_mainnet, do: "Mainnet", else: "Testnet"),
      signatureChainId: signature_chain_id(is_mainnet),
      destination: destination,
      amount: amount,
      time: time
    }

    signature = %{r: sig["r"], s: sig["s"], v: sig["v"]}

    Http.user_signed_request(action, signature, time, opts)
  end

  defp signature_chain_id(true), do: Utils.from_int(42_161)
  defp signature_chain_id(false), do: Utils.from_int(421_614)

  defp generate_nonce do
    System.system_time(:millisecond)
  end
end
