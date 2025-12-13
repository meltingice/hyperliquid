defmodule Hyperliquid.Api.Subscription.L2Book do
  @moduledoc """
  WebSocket subscription for order book data.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions

  ## Usage

      {:ok, request} = L2Book.build_request(%{coin: "BTC"})
      # => {:ok, %{type: "l2Book", coin: "BTC"}}

      # With optional params
      {:ok, request} = L2Book.build_request(%{coin: "BTC", nSigFigs: 5})
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "l2Book",
    params: [:coin],
    optional_params: [:nSigFigs, :mantissa],
    connection_type: :dedicated,
    doc: "L2 order book updates - requires dedicated connection per variant",
    key_fields: [:coin, :nSigFigs, :mantissa],
    storage: [
      cache: [
        enabled: true,
        key_pattern: "l2book:{{coin}}"
      ]
    ]

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field(:coin, :string)
    field(:levels, {:array, {:array, :any}})
    field(:time, :integer)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [:coin, :levels, :time])
  end
end
