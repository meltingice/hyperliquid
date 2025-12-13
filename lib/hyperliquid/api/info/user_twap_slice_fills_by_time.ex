defmodule Hyperliquid.Api.Info.UserTwapSliceFillsByTime do
  @moduledoc """
  User's TWAP slice fills filtered by time.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "userTwapSliceFillsByTime",
    params: [:user, :startTime],
    optional_params: [:endTime, :aggregateByTime],
    rate_limit_cost: 1,
    doc: "Retrieve user's TWAP slice fills filtered by time",
    returns: "Individual slice fills from TWAP orders within time range",
    storage: [
      postgres: [
        enabled: true,
        table: "twap_slice_fills",
        extract: :records
      ],
      cache: [
        enabled: true,
        ttl: :timer.minutes(1),
        key_pattern: "twap_slice_fills:{{user}}:{{startTime}}"
      ]
    ]

  alias Hyperliquid.Transport.Http

  @type t :: %__MODULE__{
          records: [Record.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :records, Record, primary_key: false do
      @moduledoc "TWAP slice fill record."

      field(:twap_id, :integer)

      embeds_one :fill, Fill, primary_key: false do
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
    %{type: "userTwapSliceFillsByTime", user: user, startTime: start_time, endTime: end_time}
  end

  @doc """
  Fetches TWAP slice fills with optional end_time parameter.

  ## Parameters
    - `user`: User address (0x...)
    - `start_time`: Start timestamp in ms
    - `end_time`: Optional end timestamp in ms

  ## Returns
    - `{:ok, %UserTwapSliceFillsByTime{}}` - Parsed and validated data
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
    %{records: data}
  end

  def preprocess(data), do: data

  # ===================== Storage Field Mapping =====================

  @doc """
  Flatten nested record structure for postgres.
  """
  def extract_postgres_fields(record) do
    twap_id = safe_get(record, :twap_id) || safe_get(record, "twap_id")
    fill = safe_get(record, :fill) || safe_get(record, "fill") || %{}

    %{
      # Context field from request params (merged by extract_records)
      user: safe_get(record, :user) || safe_get(record, "user"),
      twap_id: twap_id,
      coin: safe_get(fill, :coin) || safe_get(fill, "coin"),
      px: safe_get(fill, :px) || safe_get(fill, "px"),
      sz: safe_get(fill, :sz) || safe_get(fill, "sz"),
      side: safe_get(fill, :side) || safe_get(fill, "side"),
      time: safe_get(fill, :time) || safe_get(fill, "time"),
      start_position: safe_get(fill, :start_position) || safe_get(fill, "startPosition"),
      dir: safe_get(fill, :dir) || safe_get(fill, "dir"),
      closed_pnl: safe_get(fill, :closed_pnl) || safe_get(fill, "closedPnl"),
      hash: safe_get(fill, :hash) || safe_get(fill, "hash"),
      oid: safe_get(fill, :oid) || safe_get(fill, "oid"),
      crossed: safe_get(fill, :crossed) || safe_get(fill, "crossed"),
      fee: safe_get(fill, :fee) || safe_get(fill, "fee"),
      tid: safe_get(fill, :tid) || safe_get(fill, "tid"),
      fee_token: safe_get(fill, :fee_token) || safe_get(fill, "feeToken")
    }
  end

  defp safe_get(%_{} = struct, key) when is_atom(key), do: Map.get(struct, key)
  defp safe_get(%_{}, _string_key), do: nil
  defp safe_get(map, key) when is_map(map), do: Map.get(map, key)
  defp safe_get(_, _), do: nil

  # ===================== Changesets =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, [])
    |> cast_embed(:records, with: &record_changeset/2)
  end

  defp record_changeset(record, attrs) do
    record
    |> cast(attrs, [:twap_id])
    |> cast_embed(:fill, with: &fill_changeset/2)
  end

  defp fill_changeset(fill, attrs) do
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
      :tid,
      :fee_token
    ])
    |> validate_required([:coin, :px, :sz, :side, :time])
  end
end
