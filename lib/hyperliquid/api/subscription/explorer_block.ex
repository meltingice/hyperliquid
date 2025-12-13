defmodule Hyperliquid.Api.Subscription.ExplorerBlock do
  @moduledoc """
  WebSocket subscription for explorer block updates.

  Connects to the RPC WebSocket endpoint for explorer data.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions

  ## Usage

      {:ok, request} = ExplorerBlock.build_request()
      # => {:ok, %{type: "explorerBlock"}}
  """

  use Hyperliquid.Api.SubscriptionEndpoint,
    request_type: "explorerBlock",
    connection_type: :dedicated,
    ws_url: &Hyperliquid.Config.rpc_ws_url/0,
    doc: "Explorer block updates - connects to RPC WebSocket",
    storage: [
      postgres: [
        enabled: true,
        table: "explorer_blocks"
      ],
      cache: [
        enabled: true,
        key_pattern: "block:{{height}}"
      ]
    ]

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field(:height, :integer)
    field(:time, :integer)
    field(:hash, :string)
    field(:proposer, :string)
    field(:num_txs, :integer)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [:height, :time, :hash, :proposer, :num_txs])
  end
end
