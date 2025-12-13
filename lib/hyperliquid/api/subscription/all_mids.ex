defmodule Hyperliquid.Api.Subscription.AllMids do
  @moduledoc """
  WebSocket subscription for all mid prices.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions

  ## Usage

      {:ok, request} = AllMids.build_request()
      # => {:ok, %{type: "allMids"}}
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "allMids",
    optional_params: [:dex],
    connection_type: :shared,
    doc: "All mid prices - can share connection"

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field(:mids, :map)
    # DEX name (nil for main dex)
    field(:dex, :string)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [:mids, :dex])
  end
end
