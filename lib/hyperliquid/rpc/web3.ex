defmodule Hyperliquid.Rpc.Web3 do
  @moduledoc """
  Web3-related JSON-RPC methods for Hyperliquid EVM.

  ## Usage

      alias Hyperliquid.Rpc.Web3

      {:ok, version} = Web3.client_version()
  """

  alias Hyperliquid.Transport.Rpc

  @type opts :: Rpc.rpc_opts()
  @type result :: Rpc.rpc_result()

  @doc """
  Get the current client version.

  ## Returns
    - `{:ok, string}` - Client version string

  ## Example

      {:ok, "Hyperliquid/v1.0.0"} = Web3.client_version()
  """
  @spec client_version(opts()) :: result()
  def client_version(opts \\ []) do
    Rpc.call("web3_clientVersion", [], opts)
  end

  @doc """
  Get the Keccak-256 hash of the given data.

  ## Parameters
    - `data`: Data to hash as hex string

  ## Returns
    - `{:ok, hex_string}` - Keccak-256 hash

  ## Example

      {:ok, hash} = Web3.sha3("0x68656c6c6f")
  """
  @spec sha3(String.t(), opts()) :: result()
  def sha3(data, opts \\ []) do
    Rpc.call("web3_sha3", [data], opts)
  end
end
