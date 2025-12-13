defmodule Hyperliquid.Api.Info.Referral do
  @moduledoc """
  Referral information for a user.

  Returns referral stats, rewards, and referrer state.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-referral-information
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "referral",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Retrieve referral information for a user",
    returns: "Referral stats, rewards, and referrer state"

  @type t :: %__MODULE__{
          referred_by: ReferredBy.t() | nil,
          cum_vlm: String.t(),
          unclaimed_rewards: String.t(),
          claimed_rewards: String.t(),
          builder_rewards: String.t(),
          referrer_state: ReferrerState.t() | nil,
          reward_history: [map()],
          token_to_state: [map()]
        }

  @primary_key false
  embedded_schema do
    embeds_one :referred_by, ReferredBy, primary_key: false do
      @moduledoc "Referrer information."

      field(:referrer, :string)
      field(:code, :string)
    end

    field(:cum_vlm, :string)
    field(:unclaimed_rewards, :string)
    field(:claimed_rewards, :string)
    field(:builder_rewards, :string)

    embeds_one :referrer_state, ReferrerState, primary_key: false do
      @moduledoc "Referrer state information."

      field(:stage, :string)

      embeds_one :data, ReferrerData, primary_key: false do
        @moduledoc "Referrer data."

        field(:code, :string)
        field(:referral_states, {:array, :map})
      end
    end

    field(:reward_history, {:array, :map})
    # Array of [token_id, state] tuples stored as raw
    field(:token_to_state, {:array, :any})
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for referral data.

  ## Parameters
    - `referral`: The referral struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(referral \\ %__MODULE__{}, attrs) do
    referral
    |> cast(attrs, [
      :cum_vlm,
      :unclaimed_rewards,
      :claimed_rewards,
      :builder_rewards,
      :reward_history,
      :token_to_state
    ])
    |> cast_embed(:referred_by, with: &referred_by_changeset/2)
    |> cast_embed(:referrer_state, with: &referrer_state_changeset/2)
    |> validate_required([:cum_vlm, :unclaimed_rewards, :claimed_rewards])
  end

  defp referred_by_changeset(referred_by, attrs) do
    referred_by
    |> cast(attrs, [:referrer, :code])
  end

  defp referrer_state_changeset(state, attrs) do
    state
    |> cast(attrs, [:stage])
    |> cast_embed(:data, with: &referrer_data_changeset/2)
  end

  defp referrer_data_changeset(data, attrs) do
    data
    |> cast(attrs, [:code, :referral_states])
  end

  # ===================== Helpers =====================

  @doc """
  Check if user was referred.

  ## Parameters
    - `referral`: The referral struct

  ## Returns
    - `boolean()`
  """
  @spec was_referred?(t()) :: boolean()
  def was_referred?(%__MODULE__{referred_by: nil}), do: false
  def was_referred?(%__MODULE__{referred_by: _}), do: true

  @doc """
  Get the referrer address.

  ## Parameters
    - `referral`: The referral struct

  ## Returns
    - `{:ok, String.t()}` if referred
    - `{:error, :not_referred}` if not referred
  """
  @spec referrer(t()) :: {:ok, String.t()} | {:error, :not_referred}
  def referrer(%__MODULE__{referred_by: nil}), do: {:error, :not_referred}
  def referrer(%__MODULE__{referred_by: %{referrer: referrer}}), do: {:ok, referrer}

  @doc """
  Get total rewards (claimed + unclaimed).

  ## Parameters
    - `referral`: The referral struct

  ## Returns
    - `{:ok, float()}` - Total rewards
    - `{:error, :parse_error}` - If parsing fails
  """
  @spec total_rewards(t()) :: {:ok, float()} | {:error, :parse_error}
  def total_rewards(%__MODULE__{unclaimed_rewards: unclaimed, claimed_rewards: claimed}) do
    try do
      total = String.to_float(unclaimed) + String.to_float(claimed)
      {:ok, total}
    rescue
      _ -> {:error, :parse_error}
    end
  end

  @doc """
  Check if user has unclaimed rewards.

  ## Parameters
    - `referral`: The referral struct

  ## Returns
    - `boolean()`
  """
  @spec has_unclaimed_rewards?(t()) :: boolean()
  def has_unclaimed_rewards?(%__MODULE__{unclaimed_rewards: unclaimed}) do
    case Float.parse(unclaimed) do
      {amount, _} -> amount > 0
      :error -> false
    end
  end

  @doc """
  Get the referral code if user is a referrer.

  ## Parameters
    - `referral`: The referral struct

  ## Returns
    - `{:ok, String.t()}` if has code
    - `{:error, :no_code}` if not a referrer
  """
  @spec referral_code(t()) :: {:ok, String.t()} | {:error, :no_code}
  def referral_code(%__MODULE__{referrer_state: %{data: %{code: code}}}) when is_binary(code) do
    {:ok, code}
  end

  def referral_code(_), do: {:error, :no_code}
end
