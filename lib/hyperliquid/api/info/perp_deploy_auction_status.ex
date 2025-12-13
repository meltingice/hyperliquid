defmodule Hyperliquid.Api.Info.PerpDeployAuctionStatus do
  @moduledoc """
  Status of the perpetual deployment auction.

  Returns information about the current gas auction for deploying new perpetuals.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/perpetuals
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "perpDeployAuctionStatus",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve perpetual deployment auction status",
    returns: "Current gas auction information for deploying new perpetuals"

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
  Creates a changeset for perp deploy auction status data.

  ## Parameters
    - `status`: The auction status struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(status \\ %__MODULE__{}, attrs) do
    status
    |> cast(attrs, [:start_time_seconds, :duration_seconds, :start_gas, :current_gas, :end_gas])
    |> validate_required([:start_time_seconds, :duration_seconds, :start_gas, :current_gas])
    |> validate_number(:start_time_seconds, greater_than_or_equal_to: 0)
    |> validate_number(:duration_seconds, greater_than_or_equal_to: 0)
  end

  # ===================== Helpers =====================

  @doc """
  Check if the auction is currently active.

  ## Parameters
    - `status`: The auction status struct
    - `current_time`: Current time in seconds (Unix timestamp)

  ## Returns
    - `boolean()`
  """
  @spec active?(t(), non_neg_integer()) :: boolean()
  def active?(%__MODULE__{start_time_seconds: start, duration_seconds: duration}, current_time) do
    current_time >= start and current_time < start + duration
  end

  @doc """
  Get the end time of the auction in seconds.

  ## Parameters
    - `status`: The auction status struct

  ## Returns
    - `non_neg_integer()`
  """
  @spec end_time_seconds(t()) :: non_neg_integer()
  def end_time_seconds(%__MODULE__{start_time_seconds: start, duration_seconds: duration}) do
    start + duration
  end

  @doc """
  Get remaining time in the auction in seconds.

  ## Parameters
    - `status`: The auction status struct
    - `current_time`: Current time in seconds (Unix timestamp)

  ## Returns
    - `integer()` - Can be negative if auction has ended
  """
  @spec remaining_seconds(t(), non_neg_integer()) :: integer()
  def remaining_seconds(%__MODULE__{} = status, current_time) do
    end_time_seconds(status) - current_time
  end
end
