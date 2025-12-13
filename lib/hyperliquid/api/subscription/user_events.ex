defmodule Hyperliquid.Api.Subscription.UserEvents do
  @moduledoc """
  WebSocket subscription for user event stream.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "userEvents",
    params: [:user],
    connection_type: :user_grouped,
    doc: "User events - shares connection per user"

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field(:fills, {:array, :map})
    field(:funding, {:array, :map})
    field(:liquidation, {:array, :map})
    field(:non_user_cancel, {:array, :map})
  end

  @spec build_request(map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def build_request(params) do
    types = %{user: :string}

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> validate_required([:user])
      |> validate_format(:user, ~r/^0x[0-9a-fA-F]{40}$/)

    if changeset.valid? do
      {:ok, %{type: "userEvents", user: get_change(changeset, :user)}}
    else
      {:error, changeset}
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [:fills, :funding, :liquidation, :non_user_cancel])
  end
end
