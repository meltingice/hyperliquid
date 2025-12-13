defmodule Hyperliquid.Api.Info.CandleSnapshot do
  @moduledoc """
  OHLCV candle data for a coin.

  Returns historical candle data for charting and technical analysis.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-a-candlestick-snapshot

  ## Usage

      {:ok, candles} = CandleSnapshot.request("BTC", "1h", start_time, end_time)
      {:ok, vwap} = CandleSnapshot.vwap(candles)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "candleSnapshot",
    params: [:coin, :interval, :start_time, :end_time],
    rate_limit_cost: 2,
    doc: "Retrieve OHLCV candle data for a coin",
    returns: "Array of candles with OHLCV data and trade counts",
    storage: [
      postgres: [
        enabled: true,
        table: "candles",
        extract: :candles
      ],
      cache: [
        enabled: true,
        ttl: :timer.minutes(5),
        key_pattern: "candles:{{coin}}:{{interval}}"
      ]
    ]

  @type t :: %__MODULE__{
          coin: String.t() | nil,
          interval: String.t() | nil,
          candles: [Candle.t()]
        }

  @primary_key false
  embedded_schema do
    field(:coin, :string)
    field(:interval, :string)
    embeds_many :candles, Candle, primary_key: false do
      @moduledoc "Single candle data point."

      # Candle start time (ms)
      field(:t, :integer)
      # Timestamp (ms)
      field(:T, :integer)
      # Symbol
      field(:s, :string)
      # Interval
      field(:i, :string)
      # Open price
      field(:o, :string)
      # Close price
      field(:c, :string)
      # High price
      field(:h, :string)
      # Low price
      field(:l, :string)
      # Volume
      field(:v, :string)
      # Number of trades
      field(:n, :integer)
    end
  end

  @intervals ~w(1m 3m 5m 15m 30m 1h 2h 4h 8h 12h 1d 3d 1w 1M)

  # ===================== Custom Request Builder =====================

  @doc false
  def build_request(coin, interval, start_time, end_time) do
    %{
      type: "candleSnapshot",
      req: %{
        coin: coin,
        interval: interval,
        startTime: start_time,
        endTime: end_time
      }
    }
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    # Extract coin/interval from first candle for cache key
    first = List.first(data) || %{}
    coin = first["s"] || first[:s]
    interval = first["i"] || first[:i]
    %{coin: coin, interval: interval, candles: data}
  end

  def preprocess(data), do: data

  # ===================== Storage Field Mapping =====================

  @doc """
  Map API field names to database columns for postgres storage.
  """
  def extract_postgres_fields(candle) do
    %{
      coin: Map.get(candle, :s) || Map.get(candle, "s"),
      interval: Map.get(candle, :i) || Map.get(candle, "i"),
      open_time: Map.get(candle, :t) || Map.get(candle, "t"),
      close_time: Map.get(candle, :T) || Map.get(candle, "T"),
      open: Map.get(candle, :o) || Map.get(candle, "o"),
      high: Map.get(candle, :h) || Map.get(candle, "h"),
      low: Map.get(candle, :l) || Map.get(candle, "l"),
      close: Map.get(candle, :c) || Map.get(candle, "c"),
      volume: Map.get(candle, :v) || Map.get(candle, "v"),
      num_trades: Map.get(candle, :n) || Map.get(candle, "n")
    }
  end

  # ===================== Changesets =====================

  @doc """
  Get valid candle intervals.

  ## Returns
    - List of valid interval strings
  """
  @spec valid_intervals() :: [String.t()]
  def valid_intervals, do: @intervals

  @doc """
  Creates a changeset for candle snapshot data.

  ## Parameters
    - `snapshot`: The snapshot struct
    - `attrs`: Map with candles key

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(snapshot \\ %__MODULE__{}, attrs) do
    snapshot
    |> cast(attrs, [:coin, :interval])
    |> cast_embed(:candles, with: &candle_changeset/2)
  end

  defp candle_changeset(candle, attrs) do
    candle
    |> cast(attrs, [:t, :T, :s, :i, :o, :c, :h, :l, :v, :n])
    |> validate_required([:t, :o, :c, :h, :l, :v])
  end

  # ===================== Helpers =====================

  @doc """
  Get the latest candle.

  ## Parameters
    - `snapshot`: The candle snapshot struct

  ## Returns
    - `{:ok, Candle.t()}` if candles exist
    - `{:error, :empty}` if no candles
  """
  @spec latest(t()) :: {:ok, map()} | {:error, :empty}
  def latest(%__MODULE__{candles: []}) do
    {:error, :empty}
  end

  def latest(%__MODULE__{candles: candles}) do
    {:ok, List.last(candles)}
  end

  @doc """
  Get candles within a time range.

  ## Parameters
    - `snapshot`: The candle snapshot struct
    - `start_time`: Start timestamp in ms
    - `end_time`: End timestamp in ms

  ## Returns
    - List of candles within range
  """
  @spec in_range(t(), non_neg_integer(), non_neg_integer()) :: [map()]
  def in_range(%__MODULE__{candles: candles}, start_time, end_time) do
    Enum.filter(candles, fn candle ->
      candle.t >= start_time and candle.t <= end_time
    end)
  end

  @doc """
  Calculate VWAP (Volume Weighted Average Price) for the snapshot.

  ## Parameters
    - `snapshot`: The candle snapshot struct

  ## Returns
    - `{:ok, float()}` - VWAP value
    - `{:error, :empty}` - No candles
  """
  @spec vwap(t()) :: {:ok, float()} | {:error, :empty}
  def vwap(%__MODULE__{candles: []}) do
    {:error, :empty}
  end

  def vwap(%__MODULE__{candles: candles}) do
    {total_pv, total_v} =
      Enum.reduce(candles, {0.0, 0.0}, fn candle, {pv_acc, v_acc} ->
        # Use typical price (H+L+C)/3
        h = String.to_float(candle.h)
        l = String.to_float(candle.l)
        c = String.to_float(candle.c)
        v = String.to_float(candle.v)
        typical = (h + l + c) / 3
        {pv_acc + typical * v, v_acc + v}
      end)

    if total_v > 0 do
      {:ok, total_pv / total_v}
    else
      {:error, :empty}
    end
  end
end
