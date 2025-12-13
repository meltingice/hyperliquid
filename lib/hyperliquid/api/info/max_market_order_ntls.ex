defmodule Hyperliquid.Api.Info.MaxMarketOrderNtls do
  @moduledoc """
  Maximum market order notional values.

  Returns max notional for market orders per coin.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "maxMarketOrderNtls",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve maximum market order notional values",
    returns: "Max notional for market orders per coin"

  @type t :: %__MODULE__{
          entries: [Entry.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :entries, Entry, primary_key: false do
      @moduledoc "Max market order notional entry."

      field(:asset_index, :integer)
      field(:max_ntl, :string)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    # API returns [[asset_index, max_ntl], ...] tuples
    entries =
      Enum.map(data, fn
        [asset_index, max_ntl] when is_integer(asset_index) ->
          %{"asset_index" => asset_index, "max_ntl" => max_ntl}

        entry ->
          entry
      end)

    %{entries: entries}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for max market order ntls data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(ntls \\ %__MODULE__{}, attrs) do
    ntls
    |> cast(attrs, [])
    |> cast_embed(:entries, with: &entry_changeset/2)
  end

  defp entry_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:asset_index, :max_ntl])
    |> validate_required([:asset_index, :max_ntl])
  end

  # ===================== Helpers =====================

  @doc """
  Get max notional for an asset index.
  """
  @spec get_max(t(), integer()) :: {:ok, String.t()} | {:error, :not_found}
  def get_max(%__MODULE__{entries: entries}, asset_index) do
    case Enum.find(entries, &(&1.asset_index == asset_index)) do
      nil -> {:error, :not_found}
      entry -> {:ok, entry.max_ntl}
    end
  end

  @doc """
  Get all asset indices.
  """
  @spec asset_indices(t()) :: [integer()]
  def asset_indices(%__MODULE__{entries: entries}), do: Enum.map(entries, & &1.asset_index)
end
