defmodule Hyperliquid.Api.Subscription.SpotAssetCtxs do
  @moduledoc """
  WebSocket subscription for spot asset contexts.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "spotAssetCtxs",
    params: [],
    connection_type: :shared,
    doc: "Spot asset contexts - can share connection"

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field(:meta, :map)
    field(:asset_ctxs, {:array, :map})
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [:meta, :asset_ctxs])
  end
end
