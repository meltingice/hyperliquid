defmodule Hyperliquid.Api.Info.ValidatorL1Votes do
  @moduledoc """
  Validator L1 votes.

  Returns L1 voting information for validators.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "validatorL1Votes",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve validator L1 voting information",
    returns: "L1 voting information for validators"

  @type t :: %__MODULE__{
          votes: [Vote.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :votes, Vote, primary_key: false do
      field(:validator, :string)
      field(:vote, :string)
      field(:time, :integer)
      field(:proposal_id, :integer)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{votes: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(votes \\ %__MODULE__{}, attrs) do
    votes
    |> cast(attrs, [])
    |> cast_embed(:votes, with: &vote_changeset/2)
  end

  defp vote_changeset(vote, attrs) do
    attrs = normalize_attrs(attrs)

    vote
    |> cast(attrs, [:validator, :vote, :time, :proposal_id])
    |> validate_required([:validator, :vote, :time])
  end

  defp normalize_attrs(attrs) do
    %{
      validator: attrs["validator"] || attrs[:validator],
      vote: attrs["vote"] || attrs[:vote],
      time: attrs["time"] || attrs[:time],
      proposal_id: attrs["proposalId"] || attrs[:proposal_id]
    }
  end

  # ===================== Helpers =====================

  @spec by_validator(t(), String.t()) :: [map()]
  def by_validator(%__MODULE__{votes: votes}, validator) do
    val_lower = String.downcase(validator)
    Enum.filter(votes, &(String.downcase(&1.validator) == val_lower))
  end
end
