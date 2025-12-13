defmodule Hyperliquid.Api.Subscription.ActiveAssetData do
  @moduledoc """
  WebSocket subscription for active asset data.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "activeAssetData",
    params: [:user, :coin],
    connection_type: :user_grouped,
    doc: "Active asset data - shares connection per user"

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field(:coin, :string)
    field(:leverage, :map)
    field(:max_trade_szs, {:array, :string})
    field(:user_state, :map)
  end

  @spec build_request(map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def build_request(params) do
    types = %{user: :string, coin: :string}

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> validate_required([:user, :coin])
      |> validate_format(:user, ~r/^0x[0-9a-fA-F]{40}$/)

    if changeset.valid? do
      {:ok,
       %{
         type: "activeAssetData",
         user: get_change(changeset, :user),
         coin: get_change(changeset, :coin)
       }}
    else
      {:error, changeset}
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [:coin, :leverage, :max_trade_szs, :user_state])
  end
end
