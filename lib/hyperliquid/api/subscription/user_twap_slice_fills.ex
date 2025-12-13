defmodule Hyperliquid.Api.Subscription.UserTwapSliceFills do
  @moduledoc """
  WebSocket subscription for user TWAP slice fills.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "userTwapSliceFills",
    params: [:user],
    connection_type: :user_grouped,
    doc: "User TWAP slice fills - shares connection per user",
    storage: [
      postgres: [
        enabled: true,
        table: "twap_slice_fills"
      ],
      cache: [
        enabled: true,
        ttl: :timer.minutes(5),
        key_pattern: "twap_slice_fills:ws:{{user}}"
      ]
    ]

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    embeds_many :fills, Fill, primary_key: false do
      field(:twap_id, :integer)
      field(:fill, :map)
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
      {:ok, %{type: "userTwapSliceFills", user: get_change(changeset, :user)}}
    else
      {:error, changeset}
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [])
    |> cast_embed(:fills, with: &fill_changeset/2)
  end

  defp fill_changeset(fill, attrs) do
    fill
    |> cast(attrs, [:twap_id, :fill])
  end
end
