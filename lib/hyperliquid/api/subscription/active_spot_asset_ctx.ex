defmodule Hyperliquid.Api.Subscription.ActiveSpotAssetCtx do
  @moduledoc """
  WebSocket subscription for active spot asset context.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "activeAssetCtx",
    params: [:coin],
    connection_type: :shared,
    doc: "Active spot asset context (uses spot coins) - shared connection"

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field(:coin, :string)
    field(:ctx, :map)
  end

  @spec build_request(map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def build_request(params) do
    types = %{coin: :string}

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> validate_required([:coin])

    if changeset.valid? do
      {:ok,
       %{
         type: "activeAssetCtx",
         coin: get_change(changeset, :coin)
       }}
    else
      {:error, changeset}
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [:coin, :ctx])
  end
end
