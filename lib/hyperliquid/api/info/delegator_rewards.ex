defmodule Hyperliquid.Api.Info.DelegatorRewards do
  @moduledoc """
  User's staking rewards history.

  Returns delegation and commission rewards with timestamps.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-delegator-rewards

  ## Usage

      {:ok, rewards} = DelegatorRewards.request("0x1234...")
      {:ok, total} = DelegatorRewards.total_rewards(rewards)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "delegatorRewards",
    params: [:user],
    rate_limit_cost: 2,
    doc: "Retrieve user's staking rewards history",
    returns: "Delegation and commission rewards with timestamps"

  @type t :: %__MODULE__{
          rewards: [Reward.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :rewards, Reward, primary_key: false do
      @moduledoc "Individual reward entry."

      field(:time, :integer)
      field(:source, :string)
      field(:total_amount, :string)
    end
  end

  @sources ~w(delegation commission)

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{rewards: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Get valid reward sources.

  ## Returns
    - List of valid source strings
  """
  @spec valid_sources() :: [String.t()]
  def valid_sources, do: @sources

  @doc """
  Creates a changeset for delegator rewards data.

  ## Parameters
    - `rewards`: The delegator rewards struct
    - `attrs`: Map with rewards key

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(rewards \\ %__MODULE__{}, attrs) do
    rewards
    |> cast(attrs, [])
    |> cast_embed(:rewards, with: &reward_changeset/2)
  end

  defp reward_changeset(reward, attrs) do
    reward
    |> cast(attrs, [:time, :source, :total_amount])
    |> validate_required([:time, :source, :total_amount])
  end

  # ===================== Helpers =====================

  @doc """
  Get total rewards across all entries.

  ## Parameters
    - `rewards`: The delegator rewards struct

  ## Returns
    - `{:ok, float()}` - Total rewards
    - `{:error, :parse_error}` - If parsing fails
  """
  @spec total_rewards(t()) :: {:ok, float()} | {:error, :parse_error}
  def total_rewards(%__MODULE__{rewards: rewards}) do
    try do
      total =
        rewards
        |> Enum.map(&String.to_float(&1.total_amount))
        |> Enum.sum()

      {:ok, total}
    rescue
      _ -> {:error, :parse_error}
    end
  end

  @doc """
  Get rewards by source type.

  ## Parameters
    - `rewards`: The delegator rewards struct
    - `source`: Source type ("delegation" or "commission")

  ## Returns
    - List of rewards from the source
  """
  @spec by_source(t(), String.t()) :: [map()]
  def by_source(%__MODULE__{rewards: rewards}, source) when is_binary(source) do
    Enum.filter(rewards, &(&1.source == source))
  end

  @doc """
  Get delegation rewards only.

  ## Parameters
    - `rewards`: The delegator rewards struct

  ## Returns
    - List of delegation rewards
  """
  @spec delegation_rewards(t()) :: [map()]
  def delegation_rewards(%__MODULE__{} = rewards) do
    by_source(rewards, "delegation")
  end

  @doc """
  Get commission rewards only.

  ## Parameters
    - `rewards`: The delegator rewards struct

  ## Returns
    - List of commission rewards
  """
  @spec commission_rewards(t()) :: [map()]
  def commission_rewards(%__MODULE__{} = rewards) do
    by_source(rewards, "commission")
  end

  @doc """
  Get total rewards by source.

  ## Parameters
    - `rewards`: The delegator rewards struct
    - `source`: Source type

  ## Returns
    - `{:ok, float()}` - Total for source
    - `{:error, :parse_error}` - If parsing fails
  """
  @spec total_by_source(t(), String.t()) :: {:ok, float()} | {:error, :parse_error}
  def total_by_source(%__MODULE__{} = dr, source) do
    try do
      total =
        dr
        |> by_source(source)
        |> Enum.map(&String.to_float(&1.total_amount))
        |> Enum.sum()

      {:ok, total}
    rescue
      _ -> {:error, :parse_error}
    end
  end

  @doc """
  Get rewards within a time range.

  ## Parameters
    - `rewards`: The delegator rewards struct
    - `start_time`: Start timestamp in ms
    - `end_time`: End timestamp in ms

  ## Returns
    - List of rewards in range
  """
  @spec in_range(t(), non_neg_integer(), non_neg_integer()) :: [map()]
  def in_range(%__MODULE__{rewards: rewards}, start_time, end_time) do
    Enum.filter(rewards, fn reward ->
      reward.time >= start_time and reward.time <= end_time
    end)
  end
end
