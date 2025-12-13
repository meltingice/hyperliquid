defmodule Hyperliquid.Api.Info.DelegatorSummary do
  @moduledoc """
  Summary of user's delegation status.

  Returns totals for delegated, undelegated, and pending withdrawal amounts.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-delegator-summary
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "delegatorSummary",
    params: [:user],
    rate_limit_cost: 2,
    doc: "Retrieve summary of user's delegation status",
    returns: "Totals for delegated, undelegated, and pending withdrawal amounts"

  @type t :: %__MODULE__{
          delegated: String.t(),
          undelegated: String.t(),
          total_pending_withdrawal: String.t(),
          n_pending_withdrawals: non_neg_integer()
        }

  @primary_key false
  embedded_schema do
    field(:delegated, :string)
    field(:undelegated, :string)
    field(:total_pending_withdrawal, :string)
    field(:n_pending_withdrawals, :integer)
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for delegator summary data.

  ## Parameters
    - `summary`: The delegator summary struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(summary \\ %__MODULE__{}, attrs) do
    summary
    |> cast(attrs, [:delegated, :undelegated, :total_pending_withdrawal, :n_pending_withdrawals])
    |> validate_required([
      :delegated,
      :undelegated,
      :total_pending_withdrawal,
      :n_pending_withdrawals
    ])
    |> validate_number(:n_pending_withdrawals, greater_than_or_equal_to: 0)
  end

  @doc """
  Get total staking balance (delegated + undelegated).

  ## Parameters
    - `summary`: The delegator summary struct

  ## Returns
    - `{:ok, float()}` - Total balance
    - `{:error, :parse_error}` - If parsing fails
  """
  @spec total_balance(t()) :: {:ok, float()} | {:error, :parse_error}
  def total_balance(%__MODULE__{delegated: delegated, undelegated: undelegated}) do
    try do
      total = String.to_float(delegated) + String.to_float(undelegated)
      {:ok, total}
    rescue
      _ -> {:error, :parse_error}
    end
  end

  @doc """
  Check if there are pending withdrawals.

  ## Parameters
    - `summary`: The delegator summary struct

  ## Returns
    - `boolean()`
  """
  @spec has_pending_withdrawals?(t()) :: boolean()
  def has_pending_withdrawals?(%__MODULE__{n_pending_withdrawals: n}) do
    n > 0
  end

  @doc """
  Get delegated amount as float.

  ## Parameters
    - `summary`: The delegator summary struct

  ## Returns
    - `{:ok, float()}` - Delegated amount
    - `{:error, :parse_error}` - If parsing fails
  """
  @spec delegated_amount(t()) :: {:ok, float()} | {:error, :parse_error}
  def delegated_amount(%__MODULE__{delegated: delegated}) do
    try do
      {:ok, String.to_float(delegated)}
    rescue
      _ -> {:error, :parse_error}
    end
  end

  @doc """
  Get pending withdrawal amount as float.

  ## Parameters
    - `summary`: The delegator summary struct

  ## Returns
    - `{:ok, float()}` - Pending amount
    - `{:error, :parse_error}` - If parsing fails
  """
  @spec pending_amount(t()) :: {:ok, float()} | {:error, :parse_error}
  def pending_amount(%__MODULE__{total_pending_withdrawal: pending}) do
    try do
      {:ok, String.to_float(pending)}
    rescue
      _ -> {:error, :parse_error}
    end
  end
end
