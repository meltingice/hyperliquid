defmodule Hyperliquid.Api.Info.PerpDexs do
  @moduledoc """
  List of all perpetual DEXs.

  Returns information about all deployed perpetual DEXs including their
  names, deployers, and streaming OI caps.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/perpetuals
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "perpDexs",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve all perpetual DEXs",
    returns: "Information about all deployed perpetual DEXs",
    storage: [
      postgres: [
        enabled: true,
        table: "perp_dexs",
        # Extract individual DEX records from the dexs array
        extract: :dexs,
        # Upsert: name is the unique identifier
        conflict_target: :name,
        # Replace specific fields on conflict (all except name and inserted_at)
        on_conflict:
          {:replace,
           [
             :full_name,
             :deployer,
             :oracle_updater,
             :fee_recipient,
             :asset_to_streaming_oi_cap,
             :sub_deployers,
             :deployer_fee_scale,
             :last_deployer_fee_scale_change_time,
             :updated_at
           ]}
      ],
      cache: [enabled: false],
      # No request context params needed for this endpoint
      context_params: []
    ]

  @type t :: %__MODULE__{
          dexs: [Dex.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :dexs, Dex, primary_key: false do
      @moduledoc "Perpetual DEX information."

      field(:name, :string)
      field(:full_name, :string)
      field(:deployer, :string)
      field(:oracle_updater, :string)
      field(:fee_recipient, :string)
      # Array of [asset_name, streaming_oi_cap] tuples stored as raw
      field(:asset_to_streaming_oi_cap, {:array, :any})
      # Array of [function_name, [addresses]] tuples stored as raw
      field(:sub_deployers, {:array, :any})
      field(:deployer_fee_scale, :string)
      field(:last_deployer_fee_scale_change_time, :string)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    # Filter out null entries (main dex) and keep only valid dex objects
    dexs = Enum.filter(data, &is_map/1)
    %{dexs: dexs}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for perp dexs data.

  ## Parameters
    - `perp_dexs`: The perp dexs struct
    - `attrs`: Map with dexs key

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(perp_dexs \\ %__MODULE__{}, attrs) do
    perp_dexs
    |> cast(attrs, [])
    |> cast_embed(:dexs, with: &dex_changeset/2)
  end

  defp dex_changeset(dex, attrs) do
    dex
    |> cast(attrs, [
      :name,
      :full_name,
      :deployer,
      :oracle_updater,
      :fee_recipient,
      :asset_to_streaming_oi_cap,
      :sub_deployers,
      :deployer_fee_scale,
      :last_deployer_fee_scale_change_time
    ])
    |> validate_required([:name, :full_name, :deployer])
  end

  # ===================== Helpers =====================

  @doc """
  Find a DEX by name.

  ## Parameters
    - `perp_dexs`: The perp dexs struct
    - `name`: DEX name to find

  ## Returns
    - `{:ok, Dex.t()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec find_by_name(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def find_by_name(%__MODULE__{dexs: dexs}, name) when is_binary(name) do
    case Enum.find(dexs, &(&1.name == name)) do
      nil -> {:error, :not_found}
      dex -> {:ok, dex}
    end
  end

  @doc """
  Get all DEX names.

  ## Parameters
    - `perp_dexs`: The perp dexs struct

  ## Returns
    - List of DEX names
  """
  @spec names(t()) :: [String.t()]
  def names(%__MODULE__{dexs: dexs}) do
    Enum.map(dexs, & &1.name)
  end

  @doc """
  Get DEXs deployed by a specific address.

  ## Parameters
    - `perp_dexs`: The perp dexs struct
    - `deployer`: Deployer address

  ## Returns
    - List of DEXs deployed by the address
  """
  @spec by_deployer(t(), String.t()) :: [map()]
  def by_deployer(%__MODULE__{dexs: dexs}, deployer) when is_binary(deployer) do
    deployer_lower = String.downcase(deployer)
    Enum.filter(dexs, &(String.downcase(&1.deployer) == deployer_lower))
  end
end
