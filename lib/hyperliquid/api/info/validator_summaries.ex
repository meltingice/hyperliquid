defmodule Hyperliquid.Api.Info.ValidatorSummaries do
  @moduledoc """
  Validator summaries.

  Returns summary information for all validators.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "validatorSummaries",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve validator summaries",
    returns: "Summary information for all validators"

  @type t :: %__MODULE__{
          validators: [Validator.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :validators, Validator, primary_key: false do
      field(:validator, :string)
      field(:name, :string)
      field(:stake, :integer)
      field(:commission, :string)
      field(:is_jailed, :boolean)
      field(:n_recent_blocks, :integer)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{validators: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(summaries \\ %__MODULE__{}, attrs) do
    summaries
    |> cast(attrs, [])
    |> cast_embed(:validators, with: &validator_changeset/2)
  end

  defp validator_changeset(validator, attrs) do
    validator
    |> cast(attrs, [:validator, :name, :stake, :commission, :is_jailed, :n_recent_blocks])
    |> validate_required([:validator, :name, :stake])
  end

  # ===================== Helpers =====================

  @spec find_by_address(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def find_by_address(%__MODULE__{validators: validators}, addr) do
    addr_lower = String.downcase(addr)

    case Enum.find(validators, &(String.downcase(&1.validator) == addr_lower)) do
      nil -> {:error, :not_found}
      val -> {:ok, val}
    end
  end

  @spec active_validators(t()) :: [map()]
  def active_validators(%__MODULE__{validators: validators}) do
    Enum.filter(validators, &(&1.is_jailed != true))
  end

  @spec total_stake(t()) :: {:ok, integer()}
  def total_stake(%__MODULE__{validators: validators}) do
    total = validators |> Enum.map(& &1.stake) |> Enum.sum()
    {:ok, total}
  end
end
