defmodule Hyperliquid.Api.Info.PerpDexLimits do
  @moduledoc """
  Limits for a builder-deployed perpetual DEX.

  Returns the various caps and limits configured for a specific DEX.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/perpetuals
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "perpDexLimits",
    params: [:dex],
    rate_limit_cost: 1,
    doc: "Retrieve perpetual DEX limits",
    returns: "Caps and limits configured for a specific DEX"

  @type t :: %__MODULE__{
          total_oi_cap: String.t(),
          oi_sz_cap_per_perp: String.t(),
          max_transfer_ntl: String.t(),
          coin_to_oi_cap: [CoinOiCap.t()]
        }

  @primary_key false
  embedded_schema do
    field(:total_oi_cap, :string)
    field(:oi_sz_cap_per_perp, :string)
    field(:max_transfer_ntl, :string)

    embeds_many :coin_to_oi_cap, CoinOiCap, primary_key: false do
      @moduledoc "Coin-specific open interest cap."

      field(:coin, :string)
      field(:oi_cap, :string)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  # null response means limits not found - return empty map
  def preprocess(nil), do: %{}

  def preprocess(data) when is_map(data) do
    # API returns coinToOiCap as [[coin, oi_cap], ...] tuples
    coin_to_oi_cap = data["coinToOiCap"] || data["coin_to_oi_cap"] || []

    normalized_caps =
      Enum.map(coin_to_oi_cap, fn
        [coin, oi_cap] -> %{"coin" => coin, "oi_cap" => oi_cap}
        cap when is_map(cap) -> cap
      end)

    data
    |> Map.put("coin_to_oi_cap", normalized_caps)
    |> Map.delete("coinToOiCap")
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for perp dex limits data.

  ## Parameters
    - `limits`: The limits struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(limits \\ %__MODULE__{}, attrs) do
    limits
    |> cast(attrs, [:total_oi_cap, :oi_sz_cap_per_perp, :max_transfer_ntl])
    |> cast_embed(:coin_to_oi_cap, with: &coin_oi_cap_changeset/2)

    # Don't validate_required since API can return null (converted to empty map)
  end

  defp coin_oi_cap_changeset(coin_cap, attrs) do
    coin_cap
    |> cast(attrs, [:coin, :oi_cap])
    |> validate_required([:coin, :oi_cap])
  end

  # ===================== Helpers =====================

  @doc """
  Get the OI cap for a specific coin.

  ## Parameters
    - `limits`: The limits struct
    - `coin`: Coin symbol

  ## Returns
    - `{:ok, String.t()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec get_coin_oi_cap(t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def get_coin_oi_cap(%__MODULE__{coin_to_oi_cap: caps}, coin) when is_binary(coin) do
    case Enum.find(caps, &(&1.coin == coin)) do
      nil -> {:error, :not_found}
      %{oi_cap: cap} -> {:ok, cap}
    end
  end

  @doc """
  Get all coins with specific OI caps.

  ## Parameters
    - `limits`: The limits struct

  ## Returns
    - List of coin symbols
  """
  @spec coins_with_caps(t()) :: [String.t()]
  def coins_with_caps(%__MODULE__{coin_to_oi_cap: caps}) do
    Enum.map(caps, & &1.coin)
  end
end
