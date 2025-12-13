defmodule Hyperliquid.Api.Exchange.UpdateLeverage do
  @moduledoc """
  Update leverage for a perpetual asset.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer}
  alias Hyperliquid.Transport.Http

  @doc """
  Update leverage for a perpetual asset.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `asset`: Asset index
    - `leverage`: New leverage value
    - `is_cross`: true for cross margin, false for isolated
    - `opts`: Optional parameters

  ## Options
    - `:vault_address` - Update for a vault

  ## Returns
    - `{:ok, response}` - Update result
    - `{:error, term()}` - Error details

  ## Examples

      {:ok, result} = UpdateLeverage.request(private_key, 0, 10, true)
  """
  def request(private_key, asset, leverage, is_cross, opts \\ []) do
    vault_address = Keyword.get(opts, :vault_address)
    nonce = generate_nonce()
    expires_after = Config.expires_after()

    action = %{
      type: "updateLeverage",
      asset: asset,
      isCross: is_cross,
      leverage: leverage
    }

    with {:ok, action_json} <- Jason.encode(action),
         {:ok, signature} <-
           sign_action(private_key, action_json, nonce, vault_address, expires_after) do
      Http.exchange_request(action, signature, nonce, vault_address, expires_after, opts)
    end
  end

  defp sign_action(private_key, action_json, nonce, vault_address, expires_after) do
    is_mainnet = Config.mainnet?()

    case Signer.sign_exchange_action_ex(
           private_key,
           action_json,
           nonce,
           is_mainnet,
           vault_address,
           expires_after
         ) do
      %{"r" => r, "s" => s, "v" => v} ->
        {:ok, %{r: r, s: s, v: v}}

      error ->
        {:error, {:signing_error, error}}
    end
  end

  defp generate_nonce do
    System.system_time(:millisecond)
  end
end
