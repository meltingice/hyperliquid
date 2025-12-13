defmodule Hyperliquid.Api.Subscription.ExplorerTxs do
  @moduledoc """
  WebSocket subscription for explorer transactions.

  Connects to the RPC WebSocket endpoint for explorer data.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions

  ## Usage

      # Subscribe to all transactions
      {:ok, request} = ExplorerTxs.build_request(%{})
      # => {:ok, %{type: "explorerTxs"}}

      # Subscribe to transactions for a specific address
      {:ok, request} = ExplorerTxs.build_request(%{address: "0x..."})
      # => {:ok, %{type: "explorerTxs", address: "0x..."}}
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "explorerTxs",
    optional_params: [:address],
    connection_type: :dedicated,
    ws_url: &Hyperliquid.Config.rpc_ws_url/0,
    doc: "Explorer transaction updates - connects to RPC WebSocket",
    key_fields: [:address]

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    embeds_many :txs, Tx, primary_key: false do
      field(:hash, :string)
      field(:block_height, :integer)
      field(:time, :integer)
      field(:user, :string)
      field(:action, :map)
      field(:error, :string)
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [])
    |> cast_embed(:txs, with: &tx_changeset/2)
  end

  defp tx_changeset(tx, attrs) do
    tx
    |> cast(attrs, [:hash, :block_height, :time, :user, :action, :error])
  end
end
