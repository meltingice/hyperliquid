defmodule Hyperliquid.Api.Exchange.Cancel do
  @moduledoc """
  Cancel orders on Hyperliquid by order ID.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer}
  alias Hyperliquid.Transport.Http

  # ===================== Types =====================

  @type cancel_request :: %{
          asset: non_neg_integer(),
          oid: non_neg_integer()
        }

  @type cancel_opts :: [
          vault_address: String.t()
        ]

  @type cancel_response :: %{
          status: String.t(),
          response: %{
            type: String.t(),
            data: %{
              statuses: list()
            }
          }
        }

  # ===================== Request Functions =====================

  @doc """
  Cancel a single order by order ID.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `asset`: Asset index
    - `oid`: Order ID to cancel
    - `opts`: Optional parameters

  ## Options
    - `:vault_address` - Cancel on behalf of a vault

  ## Returns
    - `{:ok, response}` - Cancel result
    - `{:error, term()}` - Error details

  ## Examples

      {:ok, result} = Cancel.cancel(private_key, 0, 12345)
  """
  @spec cancel(String.t(), non_neg_integer(), non_neg_integer(), cancel_opts()) ::
          {:ok, cancel_response()} | {:error, term()}
  def cancel(private_key, asset, oid, opts \\ []) do
    cancel_batch(private_key, [%{asset: asset, oid: oid}], opts)
  end

  @doc """
  Cancel multiple orders by order ID.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `cancels`: List of cancel requests `[%{asset: 0, oid: 123}, ...]`
    - `opts`: Optional parameters

  ## Options
    - `:vault_address` - Cancel on behalf of a vault

  ## Returns
    - `{:ok, response}` - Batch cancel result
    - `{:error, term()}` - Error details

  ## Examples

      cancels = [
        %{asset: 0, oid: 12345},
        %{asset: 0, oid: 12346}
      ]
      {:ok, result} = Cancel.cancel_batch(private_key, cancels)
  """
  @spec cancel_batch(String.t(), [cancel_request()], cancel_opts()) ::
          {:ok, cancel_response()} | {:error, term()}
  def cancel_batch(private_key, cancels, opts \\ []) do
    vault_address = Keyword.get(opts, :vault_address)

    action = build_action(cancels)
    nonce = generate_nonce()
    expires_after = Config.expires_after()

    with {:ok, action_json} <- Jason.encode(action),
         {:ok, signature} <-
           sign_action(private_key, action_json, nonce, vault_address, expires_after),
         {:ok, response} <-
           Http.exchange_request(action, signature, nonce, vault_address, expires_after) do
      {:ok, response}
    end
  end

  # ===================== Action Building =====================

  defp build_action(cancels) do
    %{
      type: "cancel",
      cancels:
        Enum.map(cancels, fn c ->
          %{
            a: c.asset,
            o: c.oid
          }
        end)
    }
  end

  # ===================== Signing =====================

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
