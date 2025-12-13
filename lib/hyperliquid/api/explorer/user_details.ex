defmodule Hyperliquid.Api.Explorer.UserDetails do
  @moduledoc """
  User transaction history from the explorer.

  Returns recent transactions for a user address.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/explorer

  ## Usage

      {:ok, details} = UserDetails.request("0x1234...")
      UserDetails.tx_count(details)
  """

  use Hyperliquid.Api.Endpoint,
    type: :explorer,
    request_type: "userDetails",
    params: [:user],
    rate_limit_cost: 2,
    doc: "Retrieve user transaction history",
    returns: "List of recent transactions for the user"

  @type tx :: %{
          time: non_neg_integer(),
          user: String.t(),
          action: map(),
          grouping: String.t()
        }

  @type t :: %__MODULE__{
          txs: [tx()]
        }

  @primary_key false
  embedded_schema do
    field(:txs, {:array, :map})
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for user details data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(details \\ %__MODULE__{}, attrs) do
    details
    |> cast(attrs, [:txs])
  end

  # ===================== Helpers =====================

  @doc """
  Get the number of transactions.
  """
  @spec tx_count(t()) :: non_neg_integer()
  def tx_count(%__MODULE__{txs: txs}) when is_list(txs), do: length(txs)
  def tx_count(_), do: 0

  @doc """
  Get the most recent transaction.
  """
  @spec latest_tx(t()) :: {:ok, tx()} | {:error, :no_transactions}
  def latest_tx(%__MODULE__{txs: [tx | _]}), do: {:ok, tx}
  def latest_tx(_), do: {:error, :no_transactions}
end
