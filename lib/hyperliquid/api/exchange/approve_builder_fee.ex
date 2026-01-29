defmodule Hyperliquid.Api.Exchange.ApproveBuilderFee do
  @moduledoc """
  Approve a builder to charge fees.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer, Utils}
  alias Hyperliquid.Api.Exchange.KeyUtils
  alias Hyperliquid.Transport.Http

  @doc """
  Approve a builder to charge fees.

  ## Parameters
    - `builder`: Builder address
    - `max_fee_rate`: Maximum fee rate in basis points (e.g., "0.001%" = "0.00001")
    - `opts`: Optional parameters

  ## Options
    - `:private_key` - Private key for signing (falls back to config)
    - `:expected_address` - When provided, validates the private key derives to this address

  ## Returns
    - `{:ok, response}` - Result
    - `{:error, term()}` - Error details

  ## Examples

      {:ok, result} = ApproveBuilderFee.request("0x...", "0.001")

  ## Breaking Change (v0.2.0)
  `private_key` was previously the first positional argument. It is now
  an option in the opts keyword list (`:private_key`).
  """
  def request(builder, max_fee_rate, opts \\ []) do
    private_key = KeyUtils.resolve_and_validate!(opts)
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
