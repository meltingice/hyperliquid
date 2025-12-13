defmodule Hyperliquid.Api.Info.UserFees do
  @moduledoc """
  User's trading fee rates.

  Returns maker and taker fee rates for a user.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-a-users-fee-rates
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "userFees",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Retrieve user's trading fee rates",
    returns: "Maker and taker fee rates"

  @type t :: %__MODULE__{
          daily_user_vlm: [map()],
          fee_schedule: map(),
          user_cross_rate: String.t(),
          user_add_rate: String.t(),
          user_spot_cross_rate: String.t(),
          user_spot_add_rate: String.t(),
          active_referral_discount: String.t(),
          trial: term(),
          fee_trial_escrow: String.t(),
          next_trial_available_timestamp: term(),
          staking_link: map() | nil,
          active_staking_discount: map()
        }

  @primary_key false
  embedded_schema do
    field(:daily_user_vlm, {:array, :map})
    field(:fee_schedule, :map)
    field(:user_cross_rate, :string)
    field(:user_add_rate, :string)
    field(:user_spot_cross_rate, :string)
    field(:user_spot_add_rate, :string)
    field(:active_referral_discount, :string)
    field(:trial, :map)
    field(:fee_trial_escrow, :string)
    field(:next_trial_available_timestamp, :integer)
    field(:staking_link, :map)
    field(:active_staking_discount, :map)
  end

  # ===================== Changesets =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(fees \\ %__MODULE__{}, attrs) do
    fees
    |> cast(attrs, [
      :daily_user_vlm,
      :fee_schedule,
      :user_cross_rate,
      :user_add_rate,
      :user_spot_cross_rate,
      :user_spot_add_rate,
      :active_referral_discount,
      :trial,
      :fee_trial_escrow,
      :next_trial_available_timestamp,
      :staking_link,
      :active_staking_discount
    ])
    |> validate_required([:user_cross_rate, :user_add_rate])
  end

  # ===================== Helpers =====================

  @doc """
  Get cross rate as float.
  """
  @spec cross_rate_float(t()) :: {:ok, float()} | {:error, :parse_error}
  def cross_rate_float(%__MODULE__{user_cross_rate: rate}) do
    case Float.parse(rate) do
      {f, _} -> {:ok, f}
      :error -> {:error, :parse_error}
    end
  end

  @doc """
  Get add rate as float.
  """
  @spec add_rate_float(t()) :: {:ok, float()} | {:error, :parse_error}
  def add_rate_float(%__MODULE__{user_add_rate: rate}) do
    case Float.parse(rate) do
      {f, _} -> {:ok, f}
      :error -> {:error, :parse_error}
    end
  end
end
