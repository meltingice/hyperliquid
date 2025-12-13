defmodule Hyperliquid.Api.Subscription.UserFundings do
  @moduledoc """
  WebSocket subscription for user's funding payments.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "userFundings",
    params: [:user],
    connection_type: :user_grouped,
    doc: "User fundings - shares connection per user"

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    embeds_many :fundings, Funding, primary_key: false do
      field(:time, :integer)
      field(:coin, :string)
      field(:usdc, :string)
      field(:szi, :string)
      field(:funding_rate, :string)
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
      {:ok, %{type: "userFundings", user: get_change(changeset, :user)}}
    else
      {:error, changeset}
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [])
    |> cast_embed(:fundings, with: &funding_changeset/2)
  end

  defp funding_changeset(funding, attrs) do
    funding
    |> cast(attrs, [:time, :coin, :usdc, :szi, :funding_rate])
  end
end
