defmodule Hyperliquid.Api.Info.UserFillsByTime do
  @moduledoc """
  User's trade fills filtered by time range.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-a-users-fills-by-time
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "userFillsByTime",
    params: [:user, :startTime],
    optional_params: [:endTime, :aggregateByTime],
    rate_limit_cost: 1,
    doc: "Retrieve user's trade fills filtered by time range",
    returns: "List of user fills within specified time range",
    storage: [
      postgres: [
        enabled: true,
        table: "fills",
        extract: :fills
      ],
      cache: [
        enabled: true,
        ttl: :timer.minutes(1),
        key_pattern: "user_fills:{{user}}:{{startTime}}"
      ]
    ]

  alias Hyperliquid.Transport.Http

  @type t :: %__MODULE__{
          fills: [Fill.t()]
        }

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
    end
  end

  # ===================== Custom Request Methods =====================

  @doc """
  Build the request payload with optional end_time parameter.

  ## Parameters
    - `user`: User address (0x...)
    - `start_time`: Start timestamp in ms
    - `end_time`: Optional end timestamp in ms

  ## Returns
    - Map with request parameters
  """
  @spec build_request_with_end_time(String.t(), non_neg_integer(), non_neg_integer()) :: map()
  def build_request_with_end_time(user, start_time, end_time)
      when is_binary(user) and is_integer(end_time) do
    %{type: "userFillsByTime", user: user, startTime: start_time, endTime: end_time}
  end

  @doc """
  Fetches user fills with optional end_time parameter.

  ## Parameters
    - `user`: User address (0x...)
    - `start_time`: Start timestamp in ms
    - `end_time`: Optional end timestamp in ms

  ## Returns
    - `{:ok, %UserFillsByTime{}}` - Parsed and validated data
    - `{:error, term()}` - Error from HTTP or validation
  """
  @spec request_with_end_time(String.t(), non_neg_integer(), non_neg_integer() | nil) ::
          {:ok, t()} | {:error, term()}
  def request_with_end_time(user, start_time, end_time) when is_integer(end_time) do
    with {:ok, data} <-
           Http.info_request(build_request_with_end_time(user, start_time, end_time)),
         {:ok, result} <- parse_response(data) do
      {:ok, result}
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{fills: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(fills \\ %__MODULE__{}, attrs) do
    fills
    |> cast(attrs, [])
    |> cast_embed(:fills, with: &fill_changeset/2)
  end

  defp fill_changeset(fill, attrs) do
    attrs = normalize_attrs(attrs)

    fill
    |> cast(attrs, [
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
      :tid
    ])
    |> validate_required([:coin, :px, :sz, :side, :time])
  end

  defp normalize_attrs(attrs) do
    %{
      coin: attrs["coin"] || attrs[:coin],
      px: attrs["px"] || attrs[:px],
      sz: attrs["sz"] || attrs[:sz],
      side: attrs["side"] || attrs[:side],
      time: attrs["time"] || attrs[:time],
      start_position: attrs["startPosition"] || attrs[:start_position],
      dir: attrs["dir"] || attrs[:dir],
      closed_pnl: attrs["closedPnl"] || attrs[:closed_pnl],
      hash: attrs["hash"] || attrs[:hash],
      oid: attrs["oid"] || attrs[:oid],
      crossed: attrs["crossed"] || attrs[:crossed],
      fee: attrs["fee"] || attrs[:fee],
      tid: attrs["tid"] || attrs[:tid]
    }
  end
end
