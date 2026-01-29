defmodule Hyperliquid.Api.Exchange.ApproveBuilderFee do
  @moduledoc """
  Approve a builder to charge fees.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer, Utils}
  alias Hyperliquid.Transport.Http

  @doc """
  Approve a builder to charge fees.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `builder`: Builder address
    - `max_fee_rate`: Maximum fee rate in basis points (e.g., "0.001%" = "0.00001")
    - `opts`: Optional parameters

  ## Returns
    - `{:ok, response}` - Result
    - `{:error, term()}` - Error details

  ## Examples

      {:ok, result} = ApproveBuilderFee.request(private_key, "0x...", "0.001")
  """
  def request(private_key, builder, max_fee_rate, opts \\ []) do
    nonce = generate_nonce()
    is_mainnet = Config.mainnet?()

    sig = Signer.sign_approve_builder_fee(private_key, builder, max_fee_rate, nonce, is_mainnet)

    action = %{
      type: "approveBuilderFee",
      hyperliquidChain: if(is_mainnet, do: "Mainnet", else: "Testnet"),
      signatureChainId: signature_chain_id(is_mainnet),
      builder: builder,
      maxFeeRate: max_fee_rate,
      nonce: nonce
    }

    signature = %{r: sig["r"], s: sig["s"], v: sig["v"]}

    Http.user_signed_request(action, signature, nonce, opts)
  end

  defp signature_chain_id(_is_mainnet), do: Utils.from_int(42_161)

  defp generate_nonce do
    System.system_time(:millisecond)
  end
end
