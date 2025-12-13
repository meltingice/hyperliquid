defmodule Hyperliquid.Transport.Rpc do
  @moduledoc """
  JSON-RPC transport for Hyperliquid EVM.

  Provides low-level JSON-RPC communication with the Hyperliquid EVM RPC endpoint.
  Supports all standard Ethereum JSON-RPC methods plus Hyperliquid-specific methods.

  ## Usage

      # Use default RPC endpoint from config
      {:ok, block_number} = Rpc.call("eth_blockNumber", [])

      # Use a named RPC endpoint from the registry
      {:ok, block_number} = Rpc.call("eth_blockNumber", [], rpc_name: :alchemy)

      # Use custom RPC endpoint (direct URL override)
      {:ok, block_number} = Rpc.call("eth_blockNumber", [], rpc_url: "https://custom-rpc.xyz")

      # Batch requests
      {:ok, results} = Rpc.batch([
        {"eth_blockNumber", []},
        {"eth_chainId", []}
      ])

  ## Configuration

  The RPC transport uses `Hyperliquid.Config` for default URL configuration:
  - `Config.rpc_base/0` - Base URL for RPC requests (defaults to official Hyperliquid RPC)

  You can override the RPC URL per-request using the `:rpc_url` option.
  """

  alias Hyperliquid.Config
  alias Hyperliquid.Error

  @default_timeout 30_000
  @default_recv_timeout 30_000
  @json_content_type "application/json"

  @type rpc_opts :: [
          rpc_url: String.t(),
          rpc_name: atom() | String.t(),
          timeout: non_neg_integer(),
          recv_timeout: non_neg_integer()
        ]

  @type rpc_result :: {:ok, any()} | {:error, Error.t()}
  @type batch_result :: {:ok, [any()]} | {:error, Error.t()}

  # ===================== Public API =====================

  @doc """
  Make a JSON-RPC call.

  ## Parameters
    - `method`: RPC method name (e.g., "eth_blockNumber")
    - `params`: List of parameters for the method
    - `opts`: Optional configuration
      - `:rpc_url` - Override default RPC URL (highest priority)
      - `:rpc_name` - Use a named RPC from the registry (e.g., :alchemy, :quicknode)
      - `:timeout` - Request timeout in ms
      - `:recv_timeout` - Receive timeout in ms

  ## Returns
    - `{:ok, result}` - RPC result
    - `{:error, %Error{}}` - Error with details

  ## Examples

      {:ok, "0x1234"} = Rpc.call("eth_blockNumber", [])

      {:ok, balance} = Rpc.call("eth_getBalance", ["0x...", "latest"])

      {:ok, block} = Rpc.call("eth_getBlockByNumber", ["0x1", true],
        rpc_name: :alchemy
      )

      {:ok, block} = Rpc.call("eth_getBlockByNumber", ["0x1", true],
        rpc_url: "https://custom-rpc.xyz"
      )
  """
  @spec call(String.t(), list(), rpc_opts()) :: rpc_result()
  def call(method, params \\ [], opts \\ []) when is_binary(method) and is_list(params) do
    rpc_url = resolve_rpc_url(opts)
    request_id = generate_request_id()

    payload = %{
      jsonrpc: "2.0",
      method: method,
      params: params,
      id: request_id
    }

    case do_request(rpc_url, payload, opts) do
      {:ok, %{"result" => result}} ->
        {:ok, result}

      {:ok, %{"error" => error}} ->
        {:error, Error.exception(error)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Make a batch of JSON-RPC calls.

  ## Parameters
    - `requests`: List of {method, params} tuples
    - `opts`: Optional configuration (same as `call/3`)

  ## Returns
    - `{:ok, results}` - List of results in same order as requests
    - `{:error, %Error{}}` - Error with details

  ## Examples

      {:ok, [block_number, chain_id]} = Rpc.batch([
        {"eth_blockNumber", []},
        {"eth_chainId", []}
      ])
  """
  @spec batch([{String.t(), list()}], rpc_opts()) :: batch_result()
  def batch(requests, opts \\ []) when is_list(requests) do
    rpc_url = resolve_rpc_url(opts)

    payload =
      requests
      |> Enum.with_index(1)
      |> Enum.map(fn {{method, params}, id} ->
        %{
          jsonrpc: "2.0",
          method: method,
          params: params,
          id: id
        }
      end)

    case do_request(rpc_url, payload, opts) do
      {:ok, responses} when is_list(responses) ->
        # Sort by ID and extract results
        sorted =
          responses
          |> Enum.sort_by(& &1["id"])
          |> Enum.map(fn
            %{"result" => result} -> {:ok, result}
            %{"error" => error} -> {:error, error}
          end)

        # Check if any errors
        if Enum.all?(sorted, &match?({:ok, _}, &1)) do
          {:ok, Enum.map(sorted, fn {:ok, result} -> result end)}
        else
          {:ok, sorted}
        end

      {:ok, %{"error" => error}} ->
        {:error, Error.exception(error)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Subscribe to events via WebSocket (if supported).

  Note: This requires a WebSocket connection to the RPC endpoint.
  Not all RPC endpoints support subscriptions.

  ## Parameters
    - `subscription_type`: Type of subscription (e.g., "newHeads", "logs")
    - `params`: Optional parameters for the subscription
    - `opts`: Optional configuration

  ## Returns
    - `{:ok, subscription_id}` - Subscription ID
    - `{:error, %Error{}}` - Error with details
  """
  @spec subscribe(String.t(), list(), rpc_opts()) :: rpc_result()
  def subscribe(subscription_type, params \\ [], opts \\ []) do
    call("eth_subscribe", [subscription_type | params], opts)
  end

  @doc """
  Unsubscribe from events.

  ## Parameters
    - `subscription_id`: ID returned from subscribe
    - `opts`: Optional configuration

  ## Returns
    - `{:ok, true}` - Successfully unsubscribed
    - `{:error, %Error{}}` - Error with details
  """
  @spec unsubscribe(String.t(), rpc_opts()) :: rpc_result()
  def unsubscribe(subscription_id, opts \\ []) do
    call("eth_unsubscribe", [subscription_id], opts)
  end

  # ===================== Helper Functions =====================

  @doc """
  Check if the RPC endpoint is reachable.

  ## Parameters
    - `opts`: Optional configuration

  ## Returns
    - `{:ok, true}` - Endpoint is reachable
    - `{:error, %Error{}}` - Error with details
  """
  @spec ping(rpc_opts()) :: {:ok, boolean()} | {:error, Error.t()}
  def ping(opts \\ []) do
    case call("net_version", [], opts) do
      {:ok, _} -> {:ok, true}
      error -> error
    end
  end

  @doc """
  Get the current RPC URL being used.

  ## Parameters
    - `opts`: Optional configuration with `:rpc_url` override

  ## Returns
    - String with the RPC URL
  """
  @spec get_rpc_url(rpc_opts()) :: String.t()
  def get_rpc_url(opts \\ []) do
    resolve_rpc_url(opts)
  end

  # ===================== Private Helpers =====================

  # Resolves the RPC URL with the following priority:
  # 1. Direct URL override (:rpc_url)
  # 2. Named RPC from registry (:rpc_name)
  # 3. Default from config (Config.rpc_base())
  defp resolve_rpc_url(opts) do
    cond do
      # Priority 1: Direct URL override
      url = Keyword.get(opts, :rpc_url) ->
        url

      # Priority 2: Named RPC from registry
      name = Keyword.get(opts, :rpc_name) ->
        case Hyperliquid.Rpc.Registry.get(name) do
          {:ok, url} ->
            url

          :error ->
            raise "Named RPC #{inspect(name)} not found in registry. Available: #{inspect(Map.keys(Hyperliquid.Rpc.Registry.list()))}"
        end

      # Priority 3: Default from config
      true ->
        Config.rpc_base()
    end
  end

  defp do_request(url, payload, opts) do
    json_body = Jason.encode!(payload)
    headers = [{"Content-Type", @json_content_type}]

    http_opts = [
      timeout: Keyword.get(opts, :timeout, @default_timeout),
      recv_timeout: Keyword.get(opts, :recv_timeout, @default_recv_timeout)
    ]

    case HTTPoison.post(url, json_body, headers, http_opts) do
      {:ok, %HTTPoison.Response{status_code: code, body: resp_body}} when code in 200..299 ->
        parse_response(resp_body)

      {:ok, %HTTPoison.Response{status_code: code, body: resp_body}} ->
        {:error, Error.exception(%{status_code: code, message: resp_body})}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, Error.exception(%{reason: reason})}
    end
  end

  defp parse_response(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, data} ->
        {:ok, data}

      {:error, _} ->
        {:error, Error.exception(%{reason: {:json_decode_error, body}})}
    end
  end

  defp generate_request_id do
    :erlang.unique_integer([:positive, :monotonic])
  end
end
