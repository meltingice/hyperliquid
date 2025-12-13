defmodule Hyperliquid.Api.Subscription.UserTwapHistory do
  @moduledoc """
  WebSocket subscription for user TWAP history.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "userTwapHistory",
    params: [:user],
    connection_type: :user_grouped,
    doc: "User TWAP history - shares connection per user"

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    embeds_many :history, HistoryEntry, primary_key: false do
      field(:twap_id, :integer)
      field(:state, :map)
      field(:status, :map)
    end
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
      {:ok, %{type: "userTwapHistory", user: get_change(changeset, :user)}}
    else
      {:error, changeset}
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [])
    |> cast_embed(:history, with: &history_changeset/2)
  end

  defp history_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:twap_id, :state, :status])
  end
end
