defmodule Hyperliquid.Api.Subscription.Candle do
  @moduledoc """
  WebSocket subscription for candlestick data.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "candle",
    params: [:coin, :interval],
    connection_type: :shared,
    doc: "Candlestick data",
    key_fields: [:coin, :interval],
    storage: [
      # Candle updates are incremental (current candle), not completed candles
      # Only cache the latest version, don't persist every update to DB
      cache: [
        enabled: true,
        key_pattern: "candle:{{s}}:{{i}}"
      ]
    ]

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field(:t, :integer)
    field(:T, :integer)
    field(:s, :string)
    field(:i, :string)
    field(:o, :string)
    field(:c, :string)
    field(:h, :string)
    field(:l, :string)
    field(:v, :string)
    field(:n, :integer)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [:t, :T, :s, :i, :o, :c, :h, :l, :v, :n])
  end
end
