defmodule Hyperliquid.Api.Subscription.Trades do
  @moduledoc """
  WebSocket subscription for recent trades.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions

  ## Usage

      {:ok, request} = Trades.build_request(%{coin: "BTC"})
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "trades",
    params: [:coin],
    connection_type: :shared,
    doc: "Recent trades - can share connection",
    storage: [
      postgres: [
        enabled: true,
        table: "trades"
      ],
      cache: [
        enabled: true,
        ttl: :timer.minutes(5),
        key_pattern: "trades:{{coin}}:{{tid}}"
      ]
    ]

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    embeds_many :trades, Trade, primary_key: false do
      field(:coin, :string)
      field(:side, :string)
      field(:px, :string)
      field(:sz, :string)
      field(:hash, :string)
      field(:time, :integer)
      # tid is 50-bit hash of (buyer_oid, seller_oid)
      # For globally unique trade id, use (block_time, coin, tid)
      field(:tid, :integer)
      field(:buyer, :string)
      field(:seller, :string)
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [])
    |> cast_embed(:trades, with: &trade_changeset/2)
  end

  defp trade_changeset(trade, attrs) do
    # Transform users array [buyer, seller] into separate fields
    attrs = transform_users(attrs)

    trade
    |> cast(attrs, [:coin, :side, :px, :sz, :hash, :time, :tid, :buyer, :seller])
  end

  # Transform users: [buyer, seller] into buyer/seller fields
  defp transform_users(%{"users" => [buyer, seller]} = attrs) do
    attrs
    |> Map.put("buyer", buyer)
    |> Map.put("seller", seller)
    |> Map.delete("users")
  end

  defp transform_users(%{users: [buyer, seller]} = attrs) do
    attrs
    |> Map.put(:buyer, buyer)
    |> Map.put(:seller, seller)
    |> Map.delete(:users)
  end

  defp transform_users(attrs), do: attrs
end
