defmodule Hyperliquid.Api.Info.FundingHistory do
  @moduledoc """
  Historical funding rates for an asset.

  Returns historical funding rate records for a perpetual asset.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/perpetuals#retrieve-historical-funding-rates

  ## Usage

      {:ok, history} = FundingHistory.request("BTC", 1700000000000)
      {:ok, rates} = FundingHistory.rates(history)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "fundingHistory",
    params: [:coin, :start_time],
    optional_params: [:end_time],
    rate_limit_cost: 2,
    doc: "Retrieve historical funding rates for an asset",
    returns: "Historical funding rate records for a perpetual asset"

  @type t :: %__MODULE__{
          records: [Record.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :records, Record, primary_key: false do
      @moduledoc "Historical funding rate record."

      field(:coin, :string)
      field(:funding_rate, :string)
      field(:premium, :string)
      field(:time, :integer)
    end
  end

  # ===================== Custom Request Builder =====================

  @doc false
  def build_request(coin, start_time, opts) do
    payload = %{type: "fundingHistory", coin: coin, startTime: start_time}

    case Keyword.get(opts, :end_time) do
      nil -> payload
      end_time -> Map.put(payload, :endTime, end_time)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{records: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for funding history data.

  ## Parameters
    - `history`: The funding history struct
    - `attrs`: Map with payments data

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(history \\ %__MODULE__{}, attrs) do
    history
    |> cast(attrs, [])
    |> cast_embed(:records, with: &record_changeset/2)
  end

  defp record_changeset(record, attrs) do
    record
    |> cast(attrs, [:coin, :funding_rate, :premium, :time])
    |> validate_required([:coin, :funding_rate, :premium, :time])
  end

  # ===================== Helpers =====================

  @doc """
  Get all funding rate records.

  ## Parameters
    - `history`: The funding history struct

  ## Returns
    - List of funding rate records
  """
  @spec rates(t()) :: [map()]
  def rates(%__MODULE__{records: records}), do: records

  @doc """
  Get records within a time range.

  ## Parameters
    - `history`: The funding history struct
    - `start_time`: Start timestamp in ms
    - `end_time`: End timestamp in ms

  ## Returns
    - List of records in range
  """
  @spec in_range(t(), non_neg_integer(), non_neg_integer()) :: [map()]
  def in_range(%__MODULE__{records: records}, start_time, end_time) do
    Enum.filter(records, fn record ->
      record.time >= start_time and record.time <= end_time
    end)
  end

  @doc """
  Get average funding rate.

  ## Parameters
    - `history`: The funding history struct

  ## Returns
    - `{:ok, float()}` - Average funding rate
    - `{:error, :no_records}` - If no records
    - `{:error, :parse_error}` - If parsing fails
  """
  @spec average_rate(t()) :: {:ok, float()} | {:error, :no_records | :parse_error}
  def average_rate(%__MODULE__{records: []}), do: {:error, :no_records}

  def average_rate(%__MODULE__{records: records}) do
    try do
      rates = Enum.map(records, &String.to_float(&1.funding_rate))
      {:ok, Enum.sum(rates) / length(rates)}
    rescue
      _ -> {:error, :parse_error}
    end
  end
end
