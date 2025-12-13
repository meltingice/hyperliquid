defmodule Hyperliquid.Api.Stats.Leaderboard do
  @moduledoc """
  Leaderboard data from the Hyperliquid stats API.

  Returns trading leaderboard with account values, performance metrics, and rankings.

  See: https://stats-data.hyperliquid.xyz/Mainnet/leaderboard

  ## Usage

      {:ok, leaderboard} = Leaderboard.request()
      {:ok, trader} = Leaderboard.get_trader(leaderboard, "0x...")
  """

  use Hyperliquid.Api.Endpoint,
    type: :stats,
    request_type: "leaderboard",
    rate_limit_cost: 0,
    doc: "Retrieve trading leaderboard",
    returns: "Leaderboard with trader rankings and performance metrics",
    storage: [
      cache: [
        enabled: true,
        ttl: :timer.minutes(15),
        key_pattern: "stats:leaderboard"
      ]
    ]

  @type window_performance :: %{
          pnl: String.t(),
          roi: String.t(),
          vlm: String.t()
        }

  @type leaderboard_row :: %{
          eth_address: String.t(),
          account_value: String.t(),
          window_performances: [{String.t(), window_performance()}],
          prize: non_neg_integer(),
          display_name: String.t() | nil
        }

  @type t :: %__MODULE__{
          leaderboard_rows: [leaderboard_row()]
        }

  @primary_key false
  embedded_schema do
    field(:leaderboard_rows, {:array, :map})
  end

  # ===================== Cache Extraction =====================

  @doc """
  Extract just the leaderboard rows list for cache storage.
  """
  def extract_cache_fields(%{leaderboard_rows: rows}), do: rows
  def extract_cache_fields(%{"leaderboard_rows" => rows}), do: rows
  def extract_cache_fields(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for leaderboard data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(leaderboard \\ %__MODULE__{}, attrs) do
    leaderboard
    |> cast(attrs, [:leaderboard_rows])
    |> validate_required([:leaderboard_rows])
  end

  @doc """
  Get the number of traders on the leaderboard.

  ## Parameters
    - `leaderboard`: The leaderboard struct

  ## Returns
    - `non_neg_integer()`
  """
  @spec trader_count(t()) :: non_neg_integer()
  def trader_count(%__MODULE__{leaderboard_rows: rows}) when is_list(rows) do
    length(rows)
  end

  def trader_count(_), do: 0

  @doc """
  Get a specific trader's row by address.

  ## Parameters
    - `leaderboard`: The leaderboard struct
    - `address`: Ethereum address (0x...)

  ## Returns
    - `{:ok, leaderboard_row()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec get_trader(t(), String.t()) :: {:ok, leaderboard_row()} | {:error, :not_found}
  def get_trader(%__MODULE__{leaderboard_rows: rows}, address) when is_list(rows) do
    normalized_address = String.downcase(address)

    case Enum.find(rows, fn row ->
           String.downcase(Map.get(row, "eth_address", "")) == normalized_address
         end) do
      nil -> {:error, :not_found}
      row -> {:ok, row}
    end
  end

  def get_trader(_, _), do: {:error, :not_found}

  @doc """
  Get top N traders from the leaderboard.

  ## Parameters
    - `leaderboard`: The leaderboard struct
    - `n`: Number of top traders to return

  ## Returns
    - `[leaderboard_row()]`
  """
  @spec top_traders(t(), non_neg_integer()) :: [leaderboard_row()]
  def top_traders(%__MODULE__{leaderboard_rows: rows}, n) when is_list(rows) and n > 0 do
    Enum.take(rows, n)
  end

  def top_traders(_, _), do: []

  @doc """
  Get performance for a specific time window from a trader's row.

  ## Parameters
    - `row`: A leaderboard row
    - `window`: Time window ("day", "week", "month", "allTime")

  ## Returns
    - `{:ok, window_performance()}` if found
    - `{:error, :not_found}` if window not found
  """
  @spec get_window_performance(leaderboard_row(), String.t()) ::
          {:ok, window_performance()} | {:error, :not_found}
  def get_window_performance(row, window) when is_map(row) do
    window_performances = Map.get(row, "window_performances", [])

    case Enum.find(window_performances, fn [w, _perf] -> w == window end) do
      nil -> {:error, :not_found}
      [_window, performance] -> {:ok, performance}
    end
  end

  def get_window_performance(_, _), do: {:error, :not_found}
end
