defmodule Hyperliquid.Api.Info.L2Book do
  @moduledoc """
  L2 order book snapshot for a coin.

  Returns bid and ask levels with prices and sizes.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-order-book

  ## Usage

      {:ok, book} = L2Book.request("BTC")
      {:ok, mid} = L2Book.mid_price(book)
      # => {:ok, 50000.5}

      # Or with bang variant
      book = L2Book.request!("BTC")
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "l2Book",
    params: [:coin],
    rate_limit_cost: 2,
    doc: "Retrieve L2 order book snapshot for a coin",
    returns: "Order book with bids/asks arrays containing price, size, and order count"

  @type t :: %__MODULE__{
          coin: String.t(),
          time: non_neg_integer(),
          levels: [Level.t()]
        }

  @primary_key false
  embedded_schema do
    field(:coin, :string)
    field(:time, :integer)

    embeds_many :levels, Level, primary_key: false do
      @moduledoc "Order book level with bids and asks."

      # Each entry is [price, size, num_orders]
      field(:bids, {:array, :map})
      field(:asks, {:array, :map})
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) do
    # Pre-process levels to convert bid/ask arrays to maps
    preprocess_levels(data)
  end

  defp preprocess_levels(data) do
    levels = data["levels"] || data[:levels] || []

    # API returns levels as [bids_array, asks_array] not as maps with keys
    processed_levels =
      case levels do
        [bids, asks] when is_list(bids) and is_list(asks) ->
          [
            %{
              bids: parse_orders(bids),
              asks: parse_orders(asks)
            }
          ]

        _ ->
          # Fallback for potential map format
          Enum.map(levels, fn level ->
            %{
              bids: parse_orders(level["bids"] || level[:bids] || []),
              asks: parse_orders(level["asks"] || level[:asks] || [])
            }
          end)
      end

    Map.put(data, "levels", processed_levels)
  end

  defp parse_orders(orders) when is_list(orders) do
    Enum.map(orders, fn
      [px, sz, n] -> %{px: px, sz: sz, n: n}
      %{"px" => px, "sz" => sz, "n" => n} -> %{px: px, sz: sz, n: n}
      other -> other
    end)
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for L2 book data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(book \\ %__MODULE__{}, attrs) do
    book
    |> cast(attrs, [:coin, :time])
    |> cast_embed(:levels, with: &level_changeset/2)
    |> validate_required([:coin, :time])
  end

  defp level_changeset(level, attrs) do
    level
    |> cast(attrs, [:bids, :asks])
  end

  # ===================== Helpers =====================

  @doc """
  Get best bid price.
  """
  @spec best_bid(t()) :: {:ok, String.t()} | {:error, :empty}
  def best_bid(%__MODULE__{levels: [%{bids: [%{px: px} | _]} | _]}) do
    {:ok, px}
  end

  def best_bid(_), do: {:error, :empty}

  @doc """
  Get best ask price.
  """
  @spec best_ask(t()) :: {:ok, String.t()} | {:error, :empty}
  def best_ask(%__MODULE__{levels: [%{asks: [%{px: px} | _]} | _]}) do
    {:ok, px}
  end

  def best_ask(_), do: {:error, :empty}

  @doc """
  Get mid price.
  """
  @spec mid_price(t()) :: {:ok, float()} | {:error, :empty}
  def mid_price(%__MODULE__{} = book) do
    with {:ok, bid} <- best_bid(book),
         {:ok, ask} <- best_ask(book) do
      mid = (String.to_float(bid) + String.to_float(ask)) / 2
      {:ok, mid}
    end
  end

  @doc """
  Get spread.
  """
  @spec spread(t()) :: {:ok, float()} | {:error, :empty}
  def spread(%__MODULE__{} = book) do
    with {:ok, bid} <- best_bid(book),
         {:ok, ask} <- best_ask(book) do
      {:ok, String.to_float(ask) - String.to_float(bid)}
    end
  end
end
