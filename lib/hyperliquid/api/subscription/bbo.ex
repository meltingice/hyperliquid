defmodule Hyperliquid.Api.Subscription.Bbo do
  @moduledoc """
  WebSocket subscription for best bid/offer.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "bbo",
    params: [:coin],
    connection_type: :shared,
    doc: "Best bid/offer - can share connection",
    storage: [
      cache: [
        enabled: true,
        key_pattern: "bbo:{{coin}}"
      ]
    ]

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field(:coin, :string)
    field(:bid_px, :string)
    field(:bid_sz, :string)
    field(:ask_px, :string)
    field(:ask_sz, :string)
    field(:time, :integer)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [:coin, :bid_px, :bid_sz, :ask_px, :ask_sz, :time])
  end
end
