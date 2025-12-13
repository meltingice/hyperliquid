defmodule Hyperliquid.Api.Info.SpotClearinghouseState do
  @moduledoc """
  Account summary for spot trading.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/spot#retrieve-a-users-token-balances

  ## Usage

      {:ok, state} = SpotClearinghouseState.request("0x1234...")
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "spotClearinghouseState",
    params: [:user],
    rate_limit_cost: 2,
    doc: "Retrieve a user's spot token balances",
    returns: "Spot clearinghouse state with balances and escrows",
    storage: [
      postgres: [
        enabled: true,
        table: "spot_states"
      ],
      cache: [
        enabled: true,
        ttl: :timer.seconds(30),
        key_pattern: "spot_state:{{user}}"
      ]
    ]

  @type t :: %__MODULE__{
          balances: [Balance.t()],
          evm_escrows: [EvmEscrow.t()] | nil
        }

  @primary_key false
  embedded_schema do
    embeds_many :balances, Balance do
      @moduledoc "Balance for a specific spot token."

      field(:coin, :string)
      field(:token, :integer)
      field(:total, :string)
      field(:hold, :string)
      field(:entry_ntl, :string)
    end

    embeds_many :evm_escrows, EvmEscrow do
      @moduledoc "Escrowed balance for a specific asset."

      field(:coin, :string)
      field(:token, :integer)
      field(:total, :string)
    end
  end

  # ===================== Changeset =====================

  @doc """
  Creates a changeset for spot clearinghouse state data.

  ## Parameters
    - `spot_clearinghouse_state`: The spot clearinghouse state struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(spot_clearinghouse_state \\ %__MODULE__{}, attrs) do
    spot_clearinghouse_state
    |> cast(attrs, [])
    |> cast_embed(:balances, with: &balance_changeset/2)
    |> cast_embed(:evm_escrows, with: &evm_escrow_changeset/2)
  end

  defp balance_changeset(balance, attrs) do
    balance
    |> cast(attrs, [:coin, :token, :total, :hold, :entry_ntl])
    |> validate_required([:coin, :token, :total, :hold, :entry_ntl])
    |> validate_number(:token, greater_than_or_equal_to: 0)
  end

  defp evm_escrow_changeset(evm_escrow, attrs) do
    evm_escrow
    |> cast(attrs, [:coin, :token, :total])
    |> validate_required([:coin, :token, :total])
    |> validate_number(:token, greater_than_or_equal_to: 0)
  end

  # ===================== Storage Field Mapping =====================

  # Override DSL-generated function to convert struct to camelCase JSONB format
  # This matches the WebSocket subscription format for consistency
  def extract_postgres_fields(data) do
    alias Hyperliquid.Utils

    %{
      user: get_field_value(data, :user),
      balances:
        (get_field_value(data, :balances) || [])
        |> Enum.map(&Utils.to_camel_case_map/1),
      evm_escrows:
        (get_field_value(data, :evm_escrows) || [])
        |> Enum.map(&Utils.to_camel_case_map/1)
    }
  end

  # Get field value from struct or map
  defp get_field_value(%_{} = struct, field), do: Map.get(struct, field)
  defp get_field_value(map, field) when is_map(map), do: Map.get(map, field)
  defp get_field_value(_, _), do: nil
end
