defmodule Hyperliquid.Rpc.Custom do
  @moduledoc """
  Hyperliquid-specific custom JSON-RPC methods.

  These methods are unique to Hyperliquid and not part of the standard Ethereum JSON-RPC spec.

  ## Usage

      alias Hyperliquid.Rpc.Custom

      {:ok, gas_price} = Custom.big_block_gas_price()
      {:ok, using_big} = Custom.using_big_blocks("0x...")
      {:ok, sys_txs} = Custom.get_system_txs_by_block_number("0x1")
  """

  alias Hyperliquid.Transport.Rpc

  @type opts :: Rpc.rpc_opts()
  @type result :: Rpc.rpc_result()
  @type address :: String.t()
  @type hash :: String.t()
  @type block_tag :: String.t()

  @doc """
  Get the base fee for the next big block.

  Big blocks are larger blocks used for batch processing on Hyperliquid.

  ## Returns
    - `{:ok, hex_string}` - Gas price in wei as hex string

  ## Example

      {:ok, "0x3b9aca00"} = Custom.big_block_gas_price()
  """
  @spec big_block_gas_price(opts()) :: result()
  def big_block_gas_price(opts \\ []) do
    Rpc.call("eth_bigBlockGasPrice", [], opts)
  end

  @doc """
  Check if an address is using big blocks.

  ## Parameters
    - `address`: Address to check

  ## Returns
    - `{:ok, boolean}` - True if using big blocks

  ## Example

      {:ok, true} = Custom.using_big_blocks("0x...")
  """
  @spec using_big_blocks(address(), opts()) :: result()
  def using_big_blocks(address, opts \\ []) do
    Rpc.call("eth_usingBigBlocks", [address], opts)
  end

  @doc """
  Get system transactions by block hash.

  Returns system transactions that originate from HyperCore.

  ## Parameters
    - `block_hash`: Hash of the block

  ## Returns
    - `{:ok, transactions}` - List of system transactions

  ## Example

      {:ok, sys_txs} = Custom.get_system_txs_by_block_hash("0x...")
  """
  @spec get_system_txs_by_block_hash(hash(), opts()) :: result()
  def get_system_txs_by_block_hash(block_hash, opts \\ []) do
    Rpc.call("eth_getSystemTxsByBlockHash", [block_hash], opts)
  end

  @doc """
  Get system transactions by block number.

  Returns system transactions that originate from HyperCore.

  ## Parameters
    - `block_number`: Block number as hex string

  ## Returns
    - `{:ok, transactions}` - List of system transactions

  ## Example

      {:ok, sys_txs} = Custom.get_system_txs_by_block_number("0x1")
  """
  @spec get_system_txs_by_block_number(block_tag(), opts()) :: result()
  def get_system_txs_by_block_number(block_number, opts \\ []) do
    Rpc.call("eth_getSystemTxsByBlockNumber", [block_number], opts)
  end

  @doc """
  Compare gas prices between small and big blocks.

  Convenience function to get both gas prices at once.

  ## Returns
    - `{:ok, %{small_block: hex, big_block: hex}}` - Both gas prices

  ## Example

      {:ok, %{small_block: "0x...", big_block: "0x..."}} = Custom.compare_gas_prices()
  """
  @spec compare_gas_prices(opts()) :: {:ok, map()} | {:error, any()}
  def compare_gas_prices(opts \\ []) do
    case Rpc.batch(
           [
             {"eth_gasPrice", []},
             {"eth_bigBlockGasPrice", []}
           ],
           opts
         ) do
      {:ok, [small, big]} ->
        {:ok, %{small_block: small, big_block: big}}

      error ->
        error
    end
  end
end
