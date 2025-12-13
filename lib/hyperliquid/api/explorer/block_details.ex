defmodule Hyperliquid.Api.Explorer.BlockDetails do
  @moduledoc """
  Block details from the Hyperliquid L1 explorer.

  Returns information about a specific block including transactions and metadata.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/explorer

  ## Usage

      {:ok, block} = BlockDetails.request(12345)
      tx_count = BlockDetails.tx_count(block)
  """

  use Hyperliquid.Api.Endpoint,
    type: :explorer,
    request_type: "blockDetails",
    params: [:height],
    rate_limit_cost: 2,
    doc: "Retrieve block details by height",
    returns: "Block with transactions, hash, and metadata",
    storage: [
      postgres: [
        enabled: true,
        table: "block_details"
      ],
      cache: [
        enabled: true,
        ttl: :timer.hours(24),
        key_pattern: "block:{{block_number}}"
      ]
    ]

  @type t :: %__MODULE__{
          block_number: non_neg_integer(),
          block_time: non_neg_integer(),
          hash: String.t(),
          prev_hash: String.t(),
          txs: [map()],
          proposer: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    field(:block_number, :integer)
    field(:block_time, :integer)
    field(:hash, :string)
    field(:prev_hash, :string)
    field(:proposer, :string)
    field(:txs, {:array, :map})
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_map(data) do
    # The API response is nested under "block_details" key
    block_data = Map.get(data, "block_details", data)

    # Transform API field names to schema field names
    block_data
    |> Map.put("block_number", Map.get(block_data, "height"))
    |> Map.put("prev_hash", Map.get(block_data, "prev_hash", ""))
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for block details data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(details \\ %__MODULE__{}, attrs) do
    details
    |> cast(attrs, [:block_number, :block_time, :hash, :prev_hash, :proposer, :txs])
    |> validate_required([:block_number, :block_time, :hash])
    |> validate_number(:block_number, greater_than_or_equal_to: 0)
    |> validate_number(:block_time, greater_than_or_equal_to: 0)
    |> validate_length(:hash, min: 1)
  end

  @doc """
  Get the number of transactions in the block.

  ## Parameters
    - `details`: The block details struct

  ## Returns
    - `non_neg_integer()`
  """
  @spec tx_count(t()) :: non_neg_integer()
  def tx_count(%__MODULE__{txs: txs}) when is_list(txs) do
    length(txs)
  end

  def tx_count(_), do: 0

  @doc """
  Check if block is empty (no transactions).

  ## Parameters
    - `details`: The block details struct

  ## Returns
    - `boolean()`
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{} = details) do
    tx_count(details) == 0
  end

  @doc """
  Get block time as DateTime.

  ## Parameters
    - `details`: The block details struct

  ## Returns
    - `{:ok, DateTime.t()}` if valid
    - `{:error, :invalid_time}` if invalid
  """
  @spec block_datetime(t()) :: {:ok, DateTime.t()} | {:error, :invalid_time}
  def block_datetime(%__MODULE__{block_time: block_time}) when is_integer(block_time) do
    case DateTime.from_unix(block_time, :millisecond) do
      {:ok, dt} -> {:ok, dt}
      _ -> {:error, :invalid_time}
    end
  end

  def block_datetime(_), do: {:error, :invalid_time}
end
