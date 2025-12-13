defmodule Hyperliquid.Api.Explorer.TxDetails do
  @moduledoc """
  Transaction details from the explorer.

  Returns detailed information about a specific transaction.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/explorer

  ## Usage

      {:ok, details} = TxDetails.request("0x1234...")
      TxDetails.success?(details)
  """

  use Hyperliquid.Api.Endpoint,
    type: :explorer,
    request_type: "txDetails",
    params: [:hash],
    rate_limit_cost: 2,
    doc: "Retrieve transaction details by hash",
    returns: "Transaction details with block info and status",
    storage: [
      postgres: [
        enabled: true,
        table: "transactions"
      ],
      cache: [
        enabled: true,
        ttl: :timer.hours(24),
        key_pattern: "tx:{{hash}}"
      ]
    ]

  @type t :: %__MODULE__{
          tx: map(),
          block: non_neg_integer(),
          block_time: non_neg_integer(),
          hash: String.t(),
          error: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    field(:tx, :map)
    field(:block, :integer)
    field(:block_time, :integer)
    field(:hash, :string)
    field(:error, :string)
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(%{"tx" => tx} = _data) when is_map(tx) do
    # API returns all data nested in "tx", extract to flat structure
    %{
      "tx" => tx,
      "block" => Map.get(tx, "block"),
      "block_time" => Map.get(tx, "time"),
      "hash" => Map.get(tx, "hash"),
      "error" => Map.get(tx, "error")
    }
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for tx details data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(details \\ %__MODULE__{}, attrs) do
    details
    |> cast(attrs, [:tx, :block, :block_time, :hash, :error])
    |> validate_required([:hash])
  end

  @doc """
  Check if transaction succeeded.
  """
  @spec success?(t()) :: boolean()
  def success?(%__MODULE__{error: nil}), do: true
  def success?(%__MODULE__{error: ""}), do: true
  def success?(_), do: false
end
