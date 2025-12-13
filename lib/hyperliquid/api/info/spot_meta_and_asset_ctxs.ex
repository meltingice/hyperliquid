defmodule Hyperliquid.Api.Info.SpotMetaAndAssetCtxs do
  @moduledoc """
  Metadata and context for spot assets.

  This endpoint returns a tuple of [SpotMeta, SpotAssetCtxs[]] in the TypeScript SDK,
  represented here as a schema with two fields: `meta` and `asset_ctxs`.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/spot#retrieve-spot-asset-contexts
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "spotMetaAndAssetCtxs",
    params: [],
    rate_limit_cost: 2,
    doc: "Retrieve spot metadata and asset contexts",
    returns: "Metadata and context for all spot assets"

  @type t :: %__MODULE__{
          meta: Meta.t(),
          asset_ctxs: [AssetCtx.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_one :meta, Meta do
      @moduledoc "Metadata for spot assets."

      embeds_many :universe, Universe do
        @moduledoc "Trading universe details."

        field(:tokens, {:array, :integer})
        field(:name, :string)
        field(:index, :integer)
        field(:is_canonical, :boolean)
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

    embeds_many :asset_ctxs, AssetCtx do
      @moduledoc "Context for a specific spot asset."

      field(:prev_day_px, :string)
      field(:day_ntl_vlm, :string)
      field(:mark_px, :string)
      field(:mid_px, :string)
      field(:circulating_supply, :string)
      field(:coin, :string)
      field(:total_supply, :string)
      field(:day_base_vlm, :string)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess([meta, asset_ctxs]) when is_map(meta) and is_list(asset_ctxs) do
    %{meta: meta, asset_ctxs: asset_ctxs}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for spot meta and asset contexts data.

  ## Parameters
    - `spot_meta_and_asset_ctxs`: The spot meta and asset contexts struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(spot_meta_and_asset_ctxs \\ %__MODULE__{}, attrs) do
    spot_meta_and_asset_ctxs
    |> cast(attrs, [])
    |> cast_embed(:meta, with: &meta_changeset/2)
    |> cast_embed(:asset_ctxs, with: &asset_ctx_changeset/2)
  end

  defp meta_changeset(meta, attrs) do
    meta
    |> cast(attrs, [])
    |> cast_embed(:universe, with: &universe_changeset/2)
    |> cast_embed(:tokens, with: &token_changeset/2)
  end

  defp universe_changeset(universe, attrs) do
    universe
    |> cast(attrs, [:tokens, :name, :index, :is_canonical])
    |> validate_required([:tokens, :name, :index, :is_canonical])
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

  defp asset_ctx_changeset(asset_ctx, attrs) do
    asset_ctx
    |> cast(attrs, [
      :prev_day_px,
      :day_ntl_vlm,
      :mark_px,
      :mid_px,
      :circulating_supply,
      :coin,
      :total_supply,
      :day_base_vlm
    ])
    |> validate_required([
      :prev_day_px,
      :day_ntl_vlm,
      :mark_px,
      :circulating_supply,
      :coin,
      :total_supply,
      :day_base_vlm
    ])
  end
end
