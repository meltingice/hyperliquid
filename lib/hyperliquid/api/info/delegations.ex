defmodule Hyperliquid.Api.Info.Delegations do
  @moduledoc """
  User's staking delegations.

  Returns the list of validators a user has delegated to, with amounts and lock times.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-delegations

  ## Usage

      {:ok, delegations} = Delegations.request("0x1234...")
      {:ok, total} = Delegations.total_delegated(delegations)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "delegations",
    params: [:user],
    rate_limit_cost: 2,
    doc: "Retrieve user's staking delegations",
    returns: "List of validators user has delegated to with amounts and lock times"

  @type t :: %__MODULE__{
          delegations: [Delegation.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :delegations, Delegation, primary_key: false do
      @moduledoc "Individual delegation to a validator."

      field(:validator, :string)
      field(:amount, :string)
      field(:locked_until_timestamp, :integer)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{delegations: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for delegations data.

  ## Parameters
    - `delegations`: The delegations struct
    - `attrs`: Map with delegations key

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(delegations \\ %__MODULE__{}, attrs) do
    delegations
    |> cast(attrs, [])
    |> cast_embed(:delegations, with: &delegation_changeset/2)
  end

  defp delegation_changeset(delegation, attrs) do
    delegation
    |> cast(attrs, [:validator, :amount, :locked_until_timestamp])
    |> validate_required([:validator, :amount])
  end

  # ===================== Helpers =====================

  @doc """
  Get total delegated amount.

  ## Parameters
    - `delegations`: The delegations struct

  ## Returns
    - `{:ok, float()}` - Total amount
    - `{:error, :parse_error}` - If parsing fails
  """
  @spec total_delegated(t()) :: {:ok, float()} | {:error, :parse_error}
  def total_delegated(%__MODULE__{delegations: delegations}) do
    try do
      total =
        delegations
        |> Enum.map(&String.to_float(&1.amount))
        |> Enum.sum()

      {:ok, total}
    rescue
      _ -> {:error, :parse_error}
    end
  end

  @doc """
  Get delegation to a specific validator.

  ## Parameters
    - `delegations`: The delegations struct
    - `validator`: Validator address

  ## Returns
    - `{:ok, Delegation.t()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec to_validator(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def to_validator(%__MODULE__{delegations: delegations}, validator) when is_binary(validator) do
    validator_lower = String.downcase(validator)

    case Enum.find(delegations, &(String.downcase(&1.validator) == validator_lower)) do
      nil -> {:error, :not_found}
      delegation -> {:ok, delegation}
    end
  end

  @doc """
  Get all unique validators.

  ## Parameters
    - `delegations`: The delegations struct

  ## Returns
    - List of validator addresses
  """
  @spec validators(t()) :: [String.t()]
  def validators(%__MODULE__{delegations: delegations}) do
    Enum.map(delegations, & &1.validator)
  end

  @doc """
  Get delegations that are currently locked.

  ## Parameters
    - `delegations`: The delegations struct
    - `current_time`: Current time in milliseconds

  ## Returns
    - List of locked delegations
  """
  @spec locked(t(), non_neg_integer()) :: [map()]
  def locked(%__MODULE__{delegations: delegations}, current_time) when is_integer(current_time) do
    Enum.filter(delegations, fn d ->
      d.locked_until_timestamp && d.locked_until_timestamp > current_time
    end)
  end

  @doc """
  Get delegations that are unlocked.

  ## Parameters
    - `delegations`: The delegations struct
    - `current_time`: Current time in milliseconds

  ## Returns
    - List of unlocked delegations
  """
  @spec unlocked(t(), non_neg_integer()) :: [map()]
  def unlocked(%__MODULE__{delegations: delegations}, current_time)
      when is_integer(current_time) do
    Enum.filter(delegations, fn d ->
      is_nil(d.locked_until_timestamp) || d.locked_until_timestamp <= current_time
    end)
  end
end
