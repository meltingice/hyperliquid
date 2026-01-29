defmodule Hyperliquid.Api.Exchange.CDeposit do
  @moduledoc """
  Deposit native token from spot account into staking balance.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer, Utils}
  alias Hyperliquid.Transport.Http

  @doc """
  Deposit native token from spot account into staking balance.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `wei`: Amount in wei to deposit (float * 1e8)
    - `opts`: Optional parameters

  ## Returns
    - `{:ok, response}` - Deposit result
    - `{:error, term()}` - Error details

  ## Examples

      # Deposit 1 HYPE (1 * 1e8 = 100000000)
      {:ok, result} = CDeposit.request(private_key, 100_000_000)
  """
  def request(private_key, wei, opts \\ []) do
    nonce = generate_nonce()
    is_mainnet = Config.mainnet?()

    domain = %{
      name: "HyperliquidSignTransaction",
      version: "1",
      chainId: 42_161,
      verifyingContract: "0x0000000000000000000000000000000000000000"
    }

    types = %{
      "HyperliquidTransaction:CDeposit" => [
        %{name: "hyperliquidChain", type: "string"},
        %{name: "wei", type: "uint64"},
        %{name: "nonce", type: "uint64"}
      ]
    }

    message = %{
      hyperliquidChain: if(is_mainnet, do: "Mainnet", else: "Testnet"),
      wei: wei,
      nonce: nonce
    }

    with {:ok, domain_json} <- Jason.encode(domain),
         {:ok, types_json} <- Jason.encode(types),
         {:ok, message_json} <- Jason.encode(message) do
      sig =
        Signer.sign_typed_data(
          private_key,
          domain_json,
          types_json,
          message_json,
          "HyperliquidTransaction:CDeposit"
        )

      action = %{
        type: "cDeposit",
        hyperliquidChain: if(is_mainnet, do: "Mainnet", else: "Testnet"),
        signatureChainId: signature_chain_id(is_mainnet),
        wei: wei,
        nonce: nonce
      }

      signature = %{r: sig["r"], s: sig["s"], v: sig["v"]}

      Http.user_signed_request(action, signature, nonce, opts)
    end
  end

  defp signature_chain_id(_is_mainnet), do: Utils.from_int(42_161)

  defp generate_nonce do
    System.system_time(:millisecond)
  end
end
