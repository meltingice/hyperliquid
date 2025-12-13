defmodule Hyperliquid.Rpc.Registry do
  @moduledoc """
  Dynamic registry for named RPC endpoints.

  Allows registering, retrieving, and managing multiple RPC endpoints by name at runtime.
  The registry is initialized from application configuration and can be updated dynamically.

  ## Usage

      # Register a new RPC endpoint at runtime
      Hyperliquid.Rpc.Registry.register(:alchemy, "https://arb-mainnet.g.alchemy.com/v2/KEY")

      # Get an RPC URL by name
      {:ok, url} = Hyperliquid.Rpc.Registry.get(:alchemy)

      # Use in RPC calls
      Hyperliquid.Transport.Rpc.call("eth_blockNumber", [], rpc_name: :alchemy)

      # List all registered RPCs
      Hyperliquid.Rpc.Registry.list()

      # Remove an RPC endpoint
      Hyperliquid.Rpc.Registry.unregister(:alchemy)

  ## Configuration

  Named RPCs can be configured in your config file:

      config :hyperliquid,
        named_rpcs: %{
          alchemy: "https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY",
          quicknode: "https://your-endpoint.quiknode.pro/YOUR_KEY",
          local: "http://localhost:8545"
        }
  """

  use Agent

  @type rpc_name :: atom() | String.t()
  @type rpc_url :: String.t()

  @doc """
  Starts the RPC registry.

  ## Options
    - `:rpcs` - Initial map of named RPC endpoints (default: %{})

  This is typically called by the application supervisor.
  """
  @spec start_link(keyword()) :: Agent.on_start()
  def start_link(opts \\ []) do
    initial_rpcs = Keyword.get(opts, :rpcs, %{})
    Agent.start_link(fn -> initial_rpcs end, name: __MODULE__)
  end

  @doc """
  Registers a named RPC endpoint.

  ## Parameters
    - `name` - Name to register the RPC under (atom or string)
    - `url` - RPC endpoint URL

  ## Examples

      iex> Hyperliquid.Rpc.Registry.register(:alchemy, "https://arb-mainnet.g.alchemy.com")
      :ok

      iex> Hyperliquid.Rpc.Registry.register("quicknode", "https://quicknode.com")
      :ok
  """
  @spec register(rpc_name(), rpc_url()) :: :ok
  def register(name, url) when is_binary(url) do
    Agent.update(__MODULE__, &Map.put(&1, normalize_name(name), url))
  end

  @doc """
  Gets the URL for a named RPC endpoint.

  ## Parameters
    - `name` - Name of the RPC endpoint

  ## Returns
    - `{:ok, url}` - If the RPC exists
    - `:error` - If the RPC does not exist

  ## Examples

      iex> Hyperliquid.Rpc.Registry.get(:alchemy)
      {:ok, "https://arb-mainnet.g.alchemy.com"}

      iex> Hyperliquid.Rpc.Registry.get(:nonexistent)
      :error
  """
  @spec get(rpc_name()) :: {:ok, rpc_url()} | :error
  def get(name) do
    case Agent.get(__MODULE__, &Map.get(&1, normalize_name(name))) do
      nil -> :error
      url -> {:ok, url}
    end
  end

  @doc """
  Gets the URL for a named RPC endpoint, raises if not found.

  ## Parameters
    - `name` - Name of the RPC endpoint

  ## Returns
    - `url` - The RPC URL

  ## Raises
    - `RuntimeError` if the RPC endpoint is not found

  ## Examples

      iex> Hyperliquid.Rpc.Registry.get!(:alchemy)
      "https://arb-mainnet.g.alchemy.com"
  """
  @spec get!(rpc_name()) :: rpc_url()
  def get!(name) do
    case get(name) do
      {:ok, url} -> url
      :error -> raise "RPC endpoint #{inspect(name)} not found in registry"
    end
  end

  @doc """
  Removes a named RPC endpoint from the registry.

  ## Parameters
    - `name` - Name of the RPC endpoint to remove

  ## Examples

      iex> Hyperliquid.Rpc.Registry.unregister(:alchemy)
      :ok
  """
  @spec unregister(rpc_name()) :: :ok
  def unregister(name) do
    Agent.update(__MODULE__, &Map.delete(&1, normalize_name(name)))
  end

  @doc """
  Lists all registered RPC endpoints.

  ## Returns
    - Map of all registered RPC endpoints (name => url)

  ## Examples

      iex> Hyperliquid.Rpc.Registry.list()
      %{
        alchemy: "https://arb-mainnet.g.alchemy.com",
        quicknode: "https://quicknode.com",
        local: "http://localhost:8545"
      }
  """
  @spec list() :: %{atom() => rpc_url()}
  def list do
    Agent.get(__MODULE__, & &1)
  end

  @doc """
  Checks if a named RPC endpoint exists in the registry.

  ## Parameters
    - `name` - Name of the RPC endpoint to check

  ## Returns
    - `true` if the RPC exists
    - `false` otherwise

  ## Examples

      iex> Hyperliquid.Rpc.Registry.exists?(:alchemy)
      true

      iex> Hyperliquid.Rpc.Registry.exists?(:nonexistent)
      false
  """
  @spec exists?(rpc_name()) :: boolean()
  def exists?(name) do
    Agent.get(__MODULE__, &Map.has_key?(&1, normalize_name(name)))
  end

  @doc """
  Clears all registered RPC endpoints.

  ## Examples

      iex> Hyperliquid.Rpc.Registry.clear()
      :ok
  """
  @spec clear() :: :ok
  def clear do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  # Private Helpers

  defp normalize_name(name) when is_atom(name), do: name
  defp normalize_name(name) when is_binary(name), do: String.to_atom(name)
end
