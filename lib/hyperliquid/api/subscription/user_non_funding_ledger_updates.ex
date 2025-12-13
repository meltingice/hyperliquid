defmodule Hyperliquid.Api.Subscription.UserNonFundingLedgerUpdates do
  @moduledoc """
  WebSocket subscription for ledger updates.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "userNonFundingLedgerUpdates",
    params: [:user],
    connection_type: :user_grouped,
    doc: "User non-funding ledger updates - shares connection per user"

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    embeds_many :updates, Update, primary_key: false do
      field(:time, :integer)
      field(:hash, :string)
      field(:delta, :map)
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
      {:ok, %{type: "userNonFundingLedgerUpdates", user: get_change(changeset, :user)}}
    else
      {:error, changeset}
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [])
    |> cast_embed(:updates, with: &update_changeset/2)
  end

  defp update_changeset(update, attrs) do
    update
    |> cast(attrs, [:time, :hash, :delta])
  end
end
