defmodule Hyperliquid.Rpc.Eth do
  @moduledoc """
  Standard Ethereum JSON-RPC methods for Hyperliquid EVM.

  All methods accept an optional `opts` keyword list that can include:
  - `:rpc_url` - Override the default RPC URL

  ## Important Notes

  - Methods that accept a block parameter only support `"latest"` on Hyperliquid
  - `eth_getLogs` supports up to 4 topics and 50 blocks in query range
  - `eth_maxPriorityFeePerGas` always returns zero
  - `eth_syncing` always returns false

  ## Usage

      alias Hyperliquid.Rpc.Eth

      {:ok, block_number} = Eth.block_number()
      {:ok, balance} = Eth.get_balance("0x...")
      {:ok, block} = Eth.get_block_by_number("0x1", true)
  """

  alias Hyperliquid.Transport.Rpc

  @type opts :: Rpc.rpc_opts()
  @type result :: Rpc.rpc_result()
  @type address :: String.t()
  @type block_tag :: String.t()
  @type hash :: String.t()
  @type quantity :: String.t()

  # ===================== Block Methods =====================

  @doc """
  Get the current block number.

  ## Returns
    - `{:ok, hex_string}` - Block number as hex string
  """
  @spec block_number(opts()) :: result()
  def block_number(opts \\ []) do
    Rpc.call("eth_blockNumber", [], opts)
  end

  @doc """
  Get block by hash.

  ## Parameters
    - `block_hash`: Hash of the block
    - `full_transactions`: If true, returns full transaction objects; if false, only hashes

  ## Returns
    - `{:ok, block}` - Block object or nil if not found
  """
  @spec get_block_by_hash(hash(), boolean(), opts()) :: result()
  def get_block_by_hash(block_hash, full_transactions \\ false, opts \\ []) do
    Rpc.call("eth_getBlockByHash", [block_hash, full_transactions], opts)
  end

  @doc """
  Get block by number.

  ## Parameters
    - `block_number`: Block number as hex string or "latest", "earliest", "pending"
    - `full_transactions`: If true, returns full transaction objects; if false, only hashes

  ## Returns
    - `{:ok, block}` - Block object or nil if not found
  """
  @spec get_block_by_number(block_tag(), boolean(), opts()) :: result()
  def get_block_by_number(block_number, full_transactions \\ false, opts \\ []) do
    Rpc.call("eth_getBlockByNumber", [block_number, full_transactions], opts)
  end

  @doc """
  Get the number of transactions in a block by hash.

  ## Parameters
    - `block_hash`: Hash of the block

  ## Returns
    - `{:ok, hex_string}` - Transaction count as hex string
  """
  @spec get_block_transaction_count_by_hash(hash(), opts()) :: result()
  def get_block_transaction_count_by_hash(block_hash, opts \\ []) do
    Rpc.call("eth_getBlockTransactionCountByHash", [block_hash], opts)
  end

  @doc """
  Get the number of transactions in a block by number.

  ## Parameters
    - `block_number`: Block number as hex string

  ## Returns
    - `{:ok, hex_string}` - Transaction count as hex string
  """
  @spec get_block_transaction_count_by_number(block_tag(), opts()) :: result()
  def get_block_transaction_count_by_number(block_number, opts \\ []) do
    Rpc.call("eth_getBlockTransactionCountByNumber", [block_number], opts)
  end

  @doc """
  Get all transaction receipts for a block.

  ## Parameters
    - `block_hash`: Hash of the block

  ## Returns
    - `{:ok, receipts}` - List of transaction receipts
  """
  @spec get_block_receipts(hash(), opts()) :: result()
  def get_block_receipts(block_hash, opts \\ []) do
    Rpc.call("eth_getBlockReceipts", [block_hash], opts)
  end

  # ===================== Transaction Methods =====================

  @doc """
  Get transaction by hash.

  ## Parameters
    - `tx_hash`: Transaction hash

  ## Returns
    - `{:ok, transaction}` - Transaction object or nil if not found
  """
  @spec get_transaction_by_hash(hash(), opts()) :: result()
  def get_transaction_by_hash(tx_hash, opts \\ []) do
    Rpc.call("eth_getTransactionByHash", [tx_hash], opts)
  end

  @doc """
  Get transaction by block hash and index.

  ## Parameters
    - `block_hash`: Hash of the block
    - `index`: Transaction index as hex string

  ## Returns
    - `{:ok, transaction}` - Transaction object or nil
  """
  @spec get_transaction_by_block_hash_and_index(hash(), quantity(), opts()) :: result()
  def get_transaction_by_block_hash_and_index(block_hash, index, opts \\ []) do
    Rpc.call("eth_getTransactionByBlockHashAndIndex", [block_hash, index], opts)
  end

  @doc """
  Get transaction by block number and index.

  ## Parameters
    - `block_number`: Block number as hex string
    - `index`: Transaction index as hex string

  ## Returns
    - `{:ok, transaction}` - Transaction object or nil
  """
  @spec get_transaction_by_block_number_and_index(block_tag(), quantity(), opts()) :: result()
  def get_transaction_by_block_number_and_index(block_number, index, opts \\ []) do
    Rpc.call("eth_getTransactionByBlockNumberAndIndex", [block_number, index], opts)
  end

  @doc """
  Get transaction receipt.

  ## Parameters
    - `tx_hash`: Transaction hash

  ## Returns
    - `{:ok, receipt}` - Transaction receipt or nil if not found
  """
  @spec get_transaction_receipt(hash(), opts()) :: result()
  def get_transaction_receipt(tx_hash, opts \\ []) do
    Rpc.call("eth_getTransactionReceipt", [tx_hash], opts)
  end

  @doc """
  Get the number of transactions sent from an address.

  Note: Only "latest" block is supported.

  ## Parameters
    - `address`: Address to check
    - `block`: Block tag (only "latest" supported)

  ## Returns
    - `{:ok, hex_string}` - Transaction count as hex string
  """
  @spec get_transaction_count(address(), block_tag(), opts()) :: result()
  def get_transaction_count(address, block \\ "latest", opts \\ []) do
    Rpc.call("eth_getTransactionCount", [address, block], opts)
  end

  # ===================== Account Methods =====================

  @doc """
  Get the balance of an address.

  Note: Only "latest" block is supported.

  ## Parameters
    - `address`: Address to check
    - `block`: Block tag (only "latest" supported)

  ## Returns
    - `{:ok, hex_string}` - Balance in wei as hex string
  """
  @spec get_balance(address(), block_tag(), opts()) :: result()
  def get_balance(address, block \\ "latest", opts \\ []) do
    Rpc.call("eth_getBalance", [address, block], opts)
  end

  @doc """
  Get contract code at an address.

  Note: Only "latest" block is supported.

  ## Parameters
    - `address`: Contract address
    - `block`: Block tag (only "latest" supported)

  ## Returns
    - `{:ok, hex_string}` - Contract bytecode
  """
  @spec get_code(address(), block_tag(), opts()) :: result()
  def get_code(address, block \\ "latest", opts \\ []) do
    Rpc.call("eth_getCode", [address, block], opts)
  end

  @doc """
  Get storage at a specific position.

  Note: Only "latest" block is supported.

  ## Parameters
    - `address`: Contract address
    - `position`: Storage position as hex string
    - `block`: Block tag (only "latest" supported)

  ## Returns
    - `{:ok, hex_string}` - Storage value
  """
  @spec get_storage_at(address(), quantity(), block_tag(), opts()) :: result()
  def get_storage_at(address, position, block \\ "latest", opts \\ []) do
    Rpc.call("eth_getStorageAt", [address, position, block], opts)
  end

  # ===================== Call & Estimation Methods =====================

  @doc """
  Execute a call without creating a transaction.

  Note: Only "latest" block is supported.

  ## Parameters
    - `call_object`: Map with call parameters (:from, :to, :gas, :gasPrice, :value, :data)
    - `block`: Block tag (only "latest" supported)

  ## Returns
    - `{:ok, hex_string}` - Return data
  """
  @spec call(map(), block_tag(), opts()) :: result()
  def call(call_object, block \\ "latest", opts \\ []) do
    Rpc.call("eth_call", [call_object, block], opts)
  end

  @doc """
  Estimate gas for a transaction.

  Note: Only "latest" block is supported.

  ## Parameters
    - `call_object`: Map with call parameters

  ## Returns
    - `{:ok, hex_string}` - Estimated gas as hex string
  """
  @spec estimate_gas(map(), opts()) :: result()
  def estimate_gas(call_object, opts \\ []) do
    Rpc.call("eth_estimateGas", [call_object], opts)
  end

  # ===================== Gas & Fee Methods =====================

  @doc """
  Get the current gas price.

  Returns the base fee for the next small block.

  ## Returns
    - `{:ok, hex_string}` - Gas price in wei as hex string
  """
  @spec gas_price(opts()) :: result()
  def gas_price(opts \\ []) do
    Rpc.call("eth_gasPrice", [], opts)
  end

  @doc """
  Get fee history.

  ## Parameters
    - `block_count`: Number of blocks
    - `newest_block`: Newest block number or tag
    - `reward_percentiles`: List of percentiles

  ## Returns
    - `{:ok, fee_history}` - Fee history object
  """
  @spec fee_history(non_neg_integer(), block_tag(), [number()], opts()) :: result()
  def fee_history(block_count, newest_block, reward_percentiles \\ [], opts \\ []) do
    Rpc.call("eth_feeHistory", [block_count, newest_block, reward_percentiles], opts)
  end

  @doc """
  Get max priority fee per gas.

  Note: Always returns zero on Hyperliquid currently.

  ## Returns
    - `{:ok, hex_string}` - Max priority fee as hex string (always "0x0")
  """
  @spec max_priority_fee_per_gas(opts()) :: result()
  def max_priority_fee_per_gas(opts \\ []) do
    Rpc.call("eth_maxPriorityFeePerGas", [], opts)
  end

  # ===================== Chain Methods =====================

  @doc """
  Get the chain ID.

  ## Returns
    - `{:ok, hex_string}` - Chain ID as hex string
  """
  @spec chain_id(opts()) :: result()
  def chain_id(opts \\ []) do
    Rpc.call("eth_chainId", [], opts)
  end

  @doc """
  Check if the node is syncing.

  Note: Always returns false on Hyperliquid.

  ## Returns
    - `{:ok, false}` - Node is not syncing
  """
  @spec syncing(opts()) :: result()
  def syncing(opts \\ []) do
    Rpc.call("eth_syncing", [], opts)
  end

  # ===================== Log Methods =====================

  @doc """
  Get logs matching a filter.

  Note: Supports up to 4 topics and 50 blocks in query range.

  ## Parameters
    - `filter`: Map with filter parameters
      - `:fromBlock` - Starting block (hex string or tag)
      - `:toBlock` - Ending block (hex string or tag)
      - `:address` - Contract address or list of addresses
      - `:topics` - List of topic filters (up to 4)

  ## Returns
    - `{:ok, logs}` - List of log objects

  ## Example

      filter = %{
        fromBlock: "0x1",
        toBlock: "latest",
        address: "0x...",
        topics: ["0x..."]
      }
      {:ok, logs} = Eth.get_logs(filter)
  """
  @spec get_logs(map(), opts()) :: result()
  def get_logs(filter, opts \\ []) do
    Rpc.call("eth_getLogs", [filter], opts)
  end

  # ===================== Utility Functions =====================

  @doc """
  Convert an integer to a hex string for RPC calls.

  ## Examples

      iex> to_hex(255)
      "0xff"

      iex> to_hex(0)
      "0x0"
  """
  @spec to_hex(non_neg_integer()) :: String.t()
  def to_hex(num) when is_integer(num) and num >= 0 do
    ("0x" <> Integer.to_string(num, 16)) |> String.downcase()
  end

  @doc """
  Convert a hex string to an integer.

  ## Examples

      iex> from_hex("0xff")
      255

      iex> from_hex("0x0")
      0
  """
  @spec from_hex(String.t()) :: non_neg_integer()
  def from_hex("0x" <> hex) do
    String.to_integer(hex, 16)
  end

  def from_hex(hex) when is_binary(hex) do
    String.to_integer(hex, 16)
  end

  @doc """
  Convert wei to ether.

  ## Examples

      iex> wei_to_ether("0xde0b6b3a7640000")
      1.0
  """
  @spec wei_to_ether(String.t() | non_neg_integer()) :: float()
  def wei_to_ether(wei) when is_binary(wei) do
    wei_to_ether(from_hex(wei))
  end

  def wei_to_ether(wei) when is_integer(wei) do
    wei / 1_000_000_000_000_000_000
  end

  @doc """
  Convert ether to wei.

  ## Examples

      iex> ether_to_wei(1.0)
      1000000000000000000
  """
  @spec ether_to_wei(number()) :: non_neg_integer()
  def ether_to_wei(ether) when is_number(ether) do
    round(ether * 1_000_000_000_000_000_000)
  end
end
