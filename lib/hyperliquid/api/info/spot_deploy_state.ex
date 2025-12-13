defmodule Hyperliquid.Api.Info.SpotDeployState do
  @moduledoc """
  Spot token deployment state.

  Returns deployment status for spot tokens.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint

  ## Usage

      {:ok, state} = SpotDeployState.request("0x...")
      {:ok, token} = SpotDeployState.find_by_token(state, 1)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "spotDeployState",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Retrieve spot token deployment state for user",
    returns: "Deployment status for spot tokens"

  @type t :: %__MODULE__{
          states: [State.t()],
          gas_auction: GasAuction.t()
        }

  @primary_key false
  embedded_schema do
    embeds_many :states, State, primary_key: false do
      @moduledoc "Spot token deployment state."

      field(:token, :integer)
      field(:full_name, :string)
      field(:deployer_trading_fee_share, :string)
      field(:spots, {:array, :integer})
      field(:max_supply, :string)
      field(:hyperliquidity_genesis_balance, :string)
      field(:total_genesis_balance_wei, :string)
      # Arrays of tuples stored as raw
      field(:user_genesis_balances, {:array, :any})
      field(:existing_token_genesis_balances, {:array, :any})
      field(:blacklist_users, {:array, :string})

      embeds_one :spec, Spec, primary_key: false do
        field(:name, :string)
        field(:sz_decimals, :integer)
        field(:wei_decimals, :integer)
      end
    end

    embeds_one :gas_auction, GasAuction, primary_key: false do
      @moduledoc "Deploy auction status."

      field(:current_gas, :string)
      field(:duration_seconds, :integer)
      field(:end_gas, :string)
      field(:start_gas, :string)
      field(:start_time_seconds, :integer)
    end
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for spot deploy state data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(state \\ %__MODULE__{}, attrs) do
    state
    |> cast(attrs, [])
    |> cast_embed(:states, with: &state_changeset/2)
    |> cast_embed(:gas_auction, with: &gas_auction_changeset/2)
  end

  defp state_changeset(state, attrs) do
    state
    |> cast(attrs, [
      :token,
      :full_name,
      :deployer_trading_fee_share,
      :spots,
      :max_supply,
      :hyperliquidity_genesis_balance,
      :total_genesis_balance_wei,
      :user_genesis_balances,
      :existing_token_genesis_balances,
      :blacklist_users
    ])
    |> cast_embed(:spec, with: &spec_changeset/2)
    |> validate_required([:token])
  end

  defp spec_changeset(spec, attrs) do
    spec
    |> cast(attrs, [:name, :sz_decimals, :wei_decimals])
    |> validate_required([:name, :sz_decimals, :wei_decimals])
  end

  defp gas_auction_changeset(auction, attrs) do
    auction
    |> cast(attrs, [:current_gas, :duration_seconds, :end_gas, :start_gas, :start_time_seconds])
    |> validate_required([:duration_seconds, :start_gas, :start_time_seconds])
  end

  # ===================== Helpers =====================

  @doc """
  Find by token index.
  """
  @spec find_by_token(t(), integer()) :: {:ok, map()} | {:error, :not_found}
  def find_by_token(%__MODULE__{states: states}, token_id) do
    case Enum.find(states, &(&1.token == token_id)) do
      nil -> {:error, :not_found}
      state -> {:ok, state}
    end
  end
end
