defmodule Hyperliquid.Rpc.Net do
  @moduledoc """
  Network-related JSON-RPC methods for Hyperliquid EVM.

  ## Usage

      alias Hyperliquid.Rpc.Net

      {:ok, version} = Net.version()
  """

  alias Hyperliquid.Transport.Rpc

  @type opts :: Rpc.rpc_opts()
  @type result :: Rpc.rpc_result()

  @doc """
  Get the current network ID.

  ## Returns
    - `{:ok, string}` - Network ID as string (e.g., "1" for mainnet)

  ## Example

      {:ok, "999"} = Net.version()
  """
  @spec version(opts()) :: result()
  def version(opts \\ []) do
    Rpc.call("net_version", [], opts)
  end

  @doc """
  Check if the client is actively listening for network connections.

  ## Returns
    - `{:ok, boolean}` - True if listening
  """
  @spec listening(opts()) :: result()
  def listening(opts \\ []) do
    Rpc.call("net_listening", [], opts)
  end

  @doc """
  Get the number of peers currently connected.

  ## Returns
    - `{:ok, hex_string}` - Peer count as hex string
  """
  @spec peer_count(opts()) :: result()
  def peer_count(opts \\ []) do
    Rpc.call("net_peerCount", [], opts)
  end
end
