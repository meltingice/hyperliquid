defmodule Hyperliquid.Api.Subscription.SpotState do
  @moduledoc """
  WebSocket subscription for spot state.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "spotState",
    params: [:user],
    connection_type: :user_grouped,
    doc: "Spot state - shares connection per user",
    storage: [
      postgres: [
        enabled: true,
        table: "spot_states"
      ],
      cache: [
        enabled: true,
        ttl: :timer.seconds(30),
        key_pattern: "spot_state:ws:{{user}}"
      ]
    ]

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    embeds_many :balances, Balance, primary_key: false do
      field(:coin, :string)
      field(:token, :string)
      field(:hold, :string)
      field(:total, :string)
    end
  end

  @spec build_request(map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def build_request(params) do
    types = %{user: :string}

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> validate_required([:user])
      |> validate_format(:user, ~r/^0x[0-9a-fA-F]{40}$/)

    if changeset.valid? do
      {:ok, %{type: "spotState", user: get_change(changeset, :user)}}
    else
      {:error, changeset}
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [])
    |> cast_embed(:balances, with: &balance_changeset/2)
  end

  defp balance_changeset(balance, attrs) do
    normalized = normalize_balance_attrs(attrs)

    balance
    |> cast(normalized, [:coin, :token, :hold, :total])
  end

  # ===================== Storage Field Mapping =====================

  # Override DSL-generated function to handle nested spotState structure
  # WebSocket sends: %{"user" => "0x...", "spotState" => %{"balances" => [...]}}
  def extract_postgres_fields(data) do
    # Extract nested spotState object
    spot_state = fetch_field(data, ["spotState"], %{})

    %{
      user: fetch_field(data, ["user"], nil),
      balances: fetch_field(spot_state, ["balances"], []),
      evm_escrows: fetch_field(spot_state, ["evmEscrows", "evm_escrows"], [])
    }
  end

  defp normalize_balance_attrs(attrs) when is_map(attrs) do
    %{
      coin: fetch_field(attrs, ["coin"], nil),
      token: fetch_field(attrs, ["token"], nil),
      total: fetch_field(attrs, ["total"], nil),
      hold: fetch_field(attrs, ["hold"], nil)
    }
  end

  # Get field value, trying multiple key variants (string and atom)
  defp fetch_field(attrs, [key | rest], default) when is_binary(key) do
    case Map.get(attrs, key) do
      nil ->
        # Try atom version if it exists
        try do
          atom_key = String.to_existing_atom(key)
          Map.get(attrs, atom_key) || fetch_field(attrs, rest, default)
        rescue
          ArgumentError -> fetch_field(attrs, rest, default)
        end

      value ->
        value
    end
  end

  defp fetch_field(_attrs, [], default), do: default
end
