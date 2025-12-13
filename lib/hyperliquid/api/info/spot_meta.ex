defmodule Hyperliquid.Api.Info.SpotMeta do
  @moduledoc """
  Metadata for spot assets.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/spot#retrieve-spot-metadata
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "spotMeta",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve spot asset metadata",
    returns: "Metadata for spot trading universe and tokens",
    storage: [
      postgres: [
        enabled: true,
        # NEW: Multi-table configuration
        tables: [
          # Spot pairs table
          %{
            table: "spot_pairs",
            extract: :universe,
            conflict_target: :index,
            on_conflict:
              {:replace,
               [
                 :name,
                 :display_name,
                 :tokens,
                 :is_canonical,
                 :updated_at
               ]}
          },
          # Tokens table
          %{
            table: "tokens",
            extract: :tokens,
            conflict_target: :index,
            on_conflict:
              {:replace,
               [
                 :name,
                 :sz_decimals,
                 :wei_decimals,
                 :token_id,
                 :is_canonical,
                 :full_name,
                 :deployer_trading_fee_share,
                 :evm_contract,
                 :updated_at
               ]},
            transform: &__MODULE__.transform_tokens/1
          }
        ]
      ],
      cache: [enabled: false],
      context_params: []
    ]

  @type t :: %__MODULE__{
          universe: [Universe.t()],
          tokens: [Token.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :universe, Universe do
      @moduledoc "Trading universe details."

      field(:tokens, {:array, :integer})
      field(:name, :string)
      field(:index, :integer)
      field(:is_canonical, :boolean)
      # Computed field: "TOKEN0/TOKEN1" (e.g., "PURR/USDC")
      field(:display_name, :string)
    end

    embeds_many :tokens, Token do
      @moduledoc "Spot token details."

      field(:name, :string)
      field(:sz_decimals, :integer)
      field(:wei_decimals, :integer)
      field(:index, :integer)
      field(:token_id, :string)
      field(:is_canonical, :boolean)
      field(:full_name, :string)
      field(:deployer_trading_fee_share, :string)

      embeds_one :evm_contract, EvmContract do
        @moduledoc "EVM contract details."

        field(:address, :string)
        field(:evm_extra_wei_decimals, :integer)
      end
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  # Compute display_name for each spot pair by looking up token names
  def preprocess(data) when is_map(data) do
    tokens = Map.get(data, "tokens", [])

    # Build index -> name lookup
    token_names =
      Enum.reduce(tokens, %{}, fn token, acc ->
        index = Map.get(token, "index")
        name = Map.get(token, "name")
        if index && name, do: Map.put(acc, index, name), else: acc
      end)

    # Add display_name to each universe entry
    universe =
      data
      |> Map.get("universe", [])
      |> Enum.map(fn pair ->
        case Map.get(pair, "tokens") do
          [base_idx, quote_idx] ->
            base_name = Map.get(token_names, base_idx, "?")
            quote_name = Map.get(token_names, quote_idx, "?")
            Map.put(pair, "display_name", "#{base_name}/#{quote_name}")

          _ ->
            Map.put(pair, "display_name", Map.get(pair, "name", "?/?"))
        end
      end)

    Map.put(data, "universe", universe)
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for spot meta data.

  ## Parameters
    - `spot_meta`: The spot meta struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(spot_meta \\ %__MODULE__{}, attrs) do
    spot_meta
    |> cast(attrs, [])
    |> cast_embed(:universe, with: &universe_changeset/2)
    |> cast_embed(:tokens, with: &token_changeset/2)
  end

  defp universe_changeset(universe, attrs) do
    universe
    |> cast(attrs, [:tokens, :name, :index, :is_canonical, :display_name])
    |> validate_required([:tokens, :name, :index, :is_canonical, :display_name])
    |> validate_number(:index, greater_than_or_equal_to: 0)
  end

  defp token_changeset(token, attrs) do
    token
    |> cast(attrs, [
      :name,
      :sz_decimals,
      :wei_decimals,
      :index,
      :token_id,
      :is_canonical,
      :full_name,
      :deployer_trading_fee_share
    ])
    |> cast_embed(:evm_contract, with: &evm_contract_changeset/2)
    |> validate_required([
      :name,
      :sz_decimals,
      :wei_decimals,
      :index,
      :token_id,
      :is_canonical,
      :deployer_trading_fee_share
    ])
    |> validate_number(:sz_decimals, greater_than_or_equal_to: 0)
    |> validate_number(:wei_decimals, greater_than_or_equal_to: 0)
    |> validate_number(:index, greater_than_or_equal_to: 0)
  end

  defp evm_contract_changeset(evm_contract, attrs) do
    evm_contract
    |> cast(attrs, [:address, :evm_extra_wei_decimals])
    |> validate_required([:address, :evm_extra_wei_decimals])
  end

  # ===================== Transform Functions =====================

  @doc """
  Transform tokens for storage.

  Converts evm_contract embedded struct to map for JSONB storage.
  This function is called automatically by the storage layer when using fetch/0.
  """
  def transform_tokens(tokens) when is_list(tokens) do
    Enum.map(tokens, fn token ->
      # Convert evm_contract embedded struct to map for JSONB storage
      evm_contract =
        case Map.get(token, :evm_contract) do
          nil -> nil
          %{__struct__: _} = contract -> Map.from_struct(contract) |> Map.drop([:__meta__])
          map when is_map(map) -> map
        end

      # Ensure all fields are present and convert struct to map
      token
      |> (fn
            %{__struct__: _} = struct -> Map.from_struct(struct)
            map when is_map(map) -> map
          end).()
      |> Map.put(:evm_contract, evm_contract)
    end)
  end
end
