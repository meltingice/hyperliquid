defmodule Hyperliquid.Api.Subscription.UserFills do
  @moduledoc """
  WebSocket subscription for user's trade fills.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "userFills",
    params: [:user],
    optional_params: [:aggregateByTime],
    connection_type: :user_grouped,
    doc: "User fills - shares connection per user",
    storage: [
      postgres: [
        enabled: true,
        table: "fills",
        extract: "fills"
      ],
      cache: [
        enabled: true,
        ttl: :timer.minutes(1),
        key_pattern: "user_fills:ws:{{user}}"
      ]
    ]

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    embeds_many :fills, Fill, primary_key: false do
      field(:coin, :string)
      field(:px, :string)
      field(:sz, :string)
      field(:side, :string)
      field(:time, :integer)
      field(:start_position, :string)
      field(:dir, :string)
      field(:closed_pnl, :string)
      field(:hash, :string)
      field(:oid, :integer)
      field(:crossed, :boolean)
      field(:fee, :string)
      field(:tid, :integer)
      field(:fee_token, :string)
    end
  end

  @spec build_request(map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def build_request(params) do
    types = %{user: :string, aggregateByTime: :boolean}

    changeset =
      {%{}, types}
      |> cast(params, Map.keys(types))
      |> validate_required([:user])
      |> validate_format(:user, ~r/^0x[0-9a-fA-F]{40}$/)

    if changeset.valid? do
      request = %{type: "userFills", user: get_change(changeset, :user)}

      request =
        if get_change(changeset, :aggregateByTime) do
          Map.put(request, :aggregateByTime, get_change(changeset, :aggregateByTime))
        else
          request
        end

      {:ok, request}
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
    normalized = normalize_fill_attrs(attrs)

    fill
    |> cast(normalized, [
      :coin,
      :px,
      :sz,
      :side,
      :time,
      :start_position,
      :dir,
      :closed_pnl,
      :hash,
      :oid,
      :crossed,
      :fee,
      :tid,
      :fee_token
    ])
  end

  # ===================== Storage Field Mapping =====================

  # Override DSL-generated function to normalize field names
  def extract_postgres_fields(data) do
    normalize_fill_attrs(data)
  end

  defp normalize_fill_attrs(attrs) when is_map(attrs) do
    # WebSocket sends camelCase, normalize to snake_case
    %{
      # Context field from request params (merged by extract_records)
      user: fetch_field(attrs, ["user"], nil),
      coin: fetch_field(attrs, ["coin"], nil),
      px: fetch_field(attrs, ["px"], nil),
      sz: fetch_field(attrs, ["sz"], nil),
      side: fetch_field(attrs, ["side"], nil),
      time: fetch_field(attrs, ["time"], nil),
      start_position: fetch_field(attrs, ["startPosition", "start_position"], nil),
      dir: fetch_field(attrs, ["dir"], nil),
      closed_pnl: fetch_field(attrs, ["closedPnl", "closed_pnl"], nil),
      hash: fetch_field(attrs, ["hash"], nil),
      oid: fetch_field(attrs, ["oid"], nil),
      crossed: fetch_field(attrs, ["crossed"], nil),
      fee: fetch_field(attrs, ["fee"], nil),
      tid: fetch_field(attrs, ["tid"], nil),
      fee_token: fetch_field(attrs, ["feeToken", "fee_token"], nil)
    }
  end

  # Get field value, trying multiple key variants (string and atom)
  defp fetch_field(attrs, [key | rest], default) when is_binary(key) do
    case Map.get(attrs, key) do
      nil ->
        # Try atom version if it exists
        try do
          atom_key = String.to_existing_atom(key)
          Map.get(attrs, atom_key) || fetch_field(attrs, rest, default)
        rescue
          ArgumentError -> fetch_field(attrs, rest, default)
        end

      value ->
        value
    end
  end

  defp fetch_field(_attrs, [], default), do: default
end
