defmodule Hyperliquid.Api.Info.TokenDetails do
  @moduledoc """
  Token details.

  Returns detailed information about a specific token.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "tokenDetails",
    params: [:tokenId],
    rate_limit_cost: 1,
    raw_response: true,
    doc: "Retrieve token details",
    returns: "Detailed information about a specific token",
    storage: [
      postgres: [
        enabled: true,
        table: "token_details",
        # Upsert: token_id is the unique identifier
        conflict_target: :token_id,
        # Replace all fields on conflict (prices and supplies change frequently)
        on_conflict:
          {:replace,
           [
             :name,
             :max_supply,
             :total_supply,
             :circulating_supply,
             :sz_decimals,
             :wei_decimals,
             :mid_px,
             :mark_px,
             :prev_day_px,
             :genesis,
             :deployer,
             :deploy_gas,
             :deploy_time,
             :seeded_usdc,
             :non_circulating_user_balances,
             :future_emissions,
             :updated_at
           ]}
      ],
      cache: [enabled: true],
      # Include tokenId from request params in stored/cached data
      # (uses camelCase to match the param name, normalized to snake_case in extract_records)
      context_params: [:tokenId]
    ]

  @type t :: %__MODULE__{
          token_id: String.t() | nil,
          name: String.t(),
          max_supply: String.t(),
          total_supply: String.t(),
          circulating_supply: String.t(),
          sz_decimals: non_neg_integer(),
          wei_decimals: non_neg_integer(),
          mid_px: String.t(),
          mark_px: String.t(),
          prev_day_px: String.t(),
          genesis: map() | nil,
          deployer: String.t() | nil,
          deploy_gas: String.t() | nil,
          deploy_time: String.t() | nil,
          seeded_usdc: String.t(),
          non_circulating_user_balances: list(),
          future_emissions: String.t()
        }

  @primary_key false
  embedded_schema do
    # Token ID from request params (added via context_params)
    field(:token_id, :string)

    field(:name, :string)
    field(:max_supply, :string)
    field(:total_supply, :string)
    field(:circulating_supply, :string)
    field(:sz_decimals, :integer)
    field(:wei_decimals, :integer)
    field(:mid_px, :string)
    field(:mark_px, :string)
    field(:prev_day_px, :string)
    field(:genesis, :map)
    field(:deployer, :string)
    field(:deploy_gas, :string)
    field(:deploy_time, :string)
    field(:seeded_usdc, :string)
    field(:non_circulating_user_balances, {:array, :any})
    field(:future_emissions, :string)
  end

  # ===================== Preprocessing =====================

  @doc false
  # null response means token not found
  def preprocess(nil), do: %{}

  def preprocess(data) when is_map(data), do: data

  # ===================== Storage Extraction =====================

  @doc """
  Extract records for postgres insertion, normalizing tokenId -> token_id.
  """
  def extract_records(data) do
    # Get tokenId from context and normalize to snake_case
    token_id = Map.get(data, :tokenId) || Map.get(data, "tokenId")

    # Build record with normalized key
    data
    |> Map.drop([:tokenId, "tokenId"])
    |> Map.put(:token_id, token_id)
    |> List.wrap()
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for token details data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(details \\ %__MODULE__{}, attrs) do
    details
    |> cast(attrs, [
      :token_id,
      :name,
      :max_supply,
      :total_supply,
      :circulating_supply,
      :sz_decimals,
      :wei_decimals,
      :mid_px,
      :mark_px,
      :prev_day_px,
      :genesis,
      :deployer,
      :deploy_gas,
      :deploy_time,
      :seeded_usdc,
      :non_circulating_user_balances,
      :future_emissions
    ])

    # Don't validate_required since API can return null for unknown tokens
  end

  # ===================== Helpers =====================

  @doc """
  Check if token has genesis data.
  """
  @spec has_genesis?(t()) :: boolean()
  def has_genesis?(%__MODULE__{genesis: nil}), do: false
  def has_genesis?(%__MODULE__{genesis: _}), do: true
end
