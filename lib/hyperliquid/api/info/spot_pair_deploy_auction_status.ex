defmodule Hyperliquid.Api.Info.SpotPairDeployAuctionStatus do
  @moduledoc """
  Spot pair deployment auction status.

  Returns auction status for deploying new spot pairs.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "spotPairDeployAuctionStatus",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve spot pair deployment auction status",
    returns: "Auction status for deploying new spot pairs"

  @type t :: %__MODULE__{
          start_time_seconds: non_neg_integer(),
          duration_seconds: non_neg_integer(),
          start_gas: String.t(),
          current_gas: String.t(),
          end_gas: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    field(:start_time_seconds, :integer)
    field(:duration_seconds, :integer)
    field(:start_gas, :string)
    field(:current_gas, :string)
    field(:end_gas, :string)
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for spot pair deploy auction status data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(status \\ %__MODULE__{}, attrs) do
    status
    |> cast(attrs, [:start_time_seconds, :duration_seconds, :start_gas, :current_gas, :end_gas])
    |> validate_required([:start_time_seconds, :duration_seconds, :start_gas, :current_gas])
  end

  # ===================== Helpers =====================

  @doc """
  Check if auction is active.
  """
  @spec active?(t(), non_neg_integer()) :: boolean()
  def active?(%__MODULE__{start_time_seconds: start, duration_seconds: duration}, current_time) do
    current_time >= start and current_time < start + duration
  end
end
