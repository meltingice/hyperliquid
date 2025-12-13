defmodule Hyperliquid.Api.Info.RecentTrades do
  @moduledoc """
  Recent trades for a coin.

  Returns a list of recent trades with price, size, side, and timestamp.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint

  ## Usage

      {:ok, trades} = RecentTrades.request("BTC")
      {:ok, vwap} = RecentTrades.vwap(trades)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "recentTrades",
    params: [:coin],
    rate_limit_cost: 1,
    doc: "Retrieve recent trades for a coin",
    returns: "List of recent trades with price, size, side, and timestamp",
    storage: [
      # RecentTrades extracts individual trades; buyer/seller will be null
      # (subscription trades have buyer/seller populated)
      postgres: [
        enabled: true,
        table: "trades",
        extract: :trades
      ],
      cache: [
        enabled: true,
        ttl: :timer.minutes(5),
        key_pattern: "recent_trades:{{coin}}"
      ]
    ]

  @type t :: %__MODULE__{
          coin: String.t(),
          trades: [Trade.t()]
        }

  @primary_key false
  embedded_schema do
    field(:coin, :string)
    embeds_many :trades, Trade, primary_key: false do
      @moduledoc "Individual trade."

      field(:coin, :string)
      field(:side, :string)
      field(:px, :string)
      field(:sz, :string)
      field(:time, :integer)
      field(:hash, :string)
      field(:tid, :integer)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    # Extract coin from first trade for cache key
    coin = List.first(data)["coin"] || List.first(data)[:coin]
    %{coin: coin, trades: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for recent trades data.

  ## Parameters
    - `recent`: The recent trades struct
    - `attrs`: Map with trades key

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(recent \\ %__MODULE__{}, attrs) do
    recent
    |> cast(attrs, [:coin])
    |> cast_embed(:trades, with: &trade_changeset/2)
  end

  defp trade_changeset(trade, attrs) do
    trade
    |> cast(attrs, [:coin, :side, :px, :sz, :time, :hash, :tid])
    |> validate_required([:coin, :side, :px, :sz, :time])
  end

  # ===================== Helpers =====================

  @doc """
  Get buy trades only.

  ## Parameters
    - `recent`: The recent trades struct

  ## Returns
    - List of buy trades
  """
  @spec buys(t()) :: [map()]
  def buys(%__MODULE__{trades: trades}) do
    Enum.filter(trades, &(&1.side == "B"))
  end

  @doc """
  Get sell trades only.

  ## Parameters
    - `recent`: The recent trades struct

  ## Returns
    - List of sell trades
  """
  @spec sells(t()) :: [map()]
  def sells(%__MODULE__{trades: trades}) do
    Enum.filter(trades, &(&1.side == "A"))
  end

  @doc """
  Get the latest trade.

  ## Parameters
    - `recent`: The recent trades struct

  ## Returns
    - `{:ok, Trade.t()}` if trades exist
    - `{:error, :empty}` if no trades
  """
  @spec latest(t()) :: {:ok, map()} | {:error, :empty}
  def latest(%__MODULE__{trades: []}) do
    {:error, :empty}
  end

  def latest(%__MODULE__{trades: trades}) do
    {:ok, Enum.max_by(trades, & &1.time)}
  end

  @doc """
  Calculate total volume.

  ## Parameters
    - `recent`: The recent trades struct

  ## Returns
    - `{:ok, float()}` - Total volume
    - `{:error, :empty}` - No trades
  """
  @spec total_volume(t()) :: {:ok, float()} | {:error, :empty}
  def total_volume(%__MODULE__{trades: []}) do
    {:error, :empty}
  end

  def total_volume(%__MODULE__{trades: trades}) do
    total =
      trades
      |> Enum.map(&String.to_float(&1.sz))
      |> Enum.sum()

    {:ok, total}
  end

  @doc """
  Calculate VWAP (Volume Weighted Average Price).

  ## Parameters
    - `recent`: The recent trades struct

  ## Returns
    - `{:ok, float()}` - VWAP
    - `{:error, :empty}` - No trades
  """
  @spec vwap(t()) :: {:ok, float()} | {:error, :empty}
  def vwap(%__MODULE__{trades: []}) do
    {:error, :empty}
  end

  def vwap(%__MODULE__{trades: trades}) do
    {total_pv, total_v} =
      Enum.reduce(trades, {0.0, 0.0}, fn trade, {pv_acc, v_acc} ->
        px = String.to_float(trade.px)
        sz = String.to_float(trade.sz)
        {pv_acc + px * sz, v_acc + sz}
      end)

    if total_v > 0 do
      {:ok, total_pv / total_v}
    else
      {:error, :empty}
    end
  end

  @doc """
  Get trades within a time range.

  ## Parameters
    - `recent`: The recent trades struct
    - `start_time`: Start timestamp in ms
    - `end_time`: End timestamp in ms

  ## Returns
    - List of trades within range
  """
  @spec in_range(t(), non_neg_integer(), non_neg_integer()) :: [map()]
  def in_range(%__MODULE__{trades: trades}, start_time, end_time) do
    Enum.filter(trades, fn trade ->
      trade.time >= start_time and trade.time <= end_time
    end)
  end
end
