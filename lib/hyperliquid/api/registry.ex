defmodule Hyperliquid.Api.Registry do
  @moduledoc """
  Registry for discovering and introspecting API endpoints.

  This module provides functions to list all available endpoints and
  get their documentation, rate limits, and other metadata.

  ## Usage

      # List all endpoints
      Hyperliquid.Api.Registry.list_endpoints()

      # Get info for a specific endpoint
      Hyperliquid.Api.Registry.get_endpoint_info("allMids")

      # List endpoints by type
      Hyperliquid.Api.Registry.list_by_type(:info)

      # Get total rate limit cost for multiple endpoints
      Hyperliquid.Api.Registry.total_rate_limit_cost(["allMids", "l2Book"])
  """

  # Manually register endpoint modules that use the DSL
  # This list should be updated as more endpoints are migrated
  @endpoints [
    # Weight 2 endpoints
    Hyperliquid.Api.Info.AllMids,
    Hyperliquid.Api.Info.L2Book,
    Hyperliquid.Api.Info.ClearinghouseState,
    Hyperliquid.Api.Info.SpotClearinghouseState,
    Hyperliquid.Api.Info.ExchangeStatus,
    # Weight 20 endpoints
    Hyperliquid.Api.Info.Meta,
    Hyperliquid.Api.Info.OpenOrders,
    Hyperliquid.Api.Info.UserFills,
    Hyperliquid.Api.Info.UserRateLimit
  ]

  @doc """
  List all registered endpoints with their metadata.

  ## Returns

  List of endpoint info maps.

  ## Example

      iex> Hyperliquid.Api.Registry.list_endpoints()
      [
        %{endpoint: "allMids", type: :info, rate_limit_cost: 2, ...},
        %{endpoint: "l2Book", type: :info, rate_limit_cost: 2, ...}
      ]
  """
  def list_endpoints do
    @endpoints
    |> Enum.map(fn mod ->
      Code.ensure_loaded!(mod)
      mod
    end)
    |> Enum.filter(&function_exported?(&1, :__endpoint_info__, 0))
    |> Enum.map(& &1.__endpoint_info__())
  end

  @doc """
  Get endpoint info by endpoint name.

  ## Parameters

  - `name` - The endpoint name (e.g., "allMids", "l2Book")

  ## Returns

  - `{:ok, info}` - Endpoint info map
  - `{:error, :not_found}` - Endpoint not found
  """
  def get_endpoint_info(name) when is_binary(name) do
    case Enum.find(list_endpoints(), &(&1.endpoint == name)) do
      nil -> {:error, :not_found}
      info -> {:ok, info}
    end
  end

  @doc """
  List endpoints by type.

  ## Parameters

  - `type` - `:info`, `:exchange`, or `:subscription`

  ## Returns

  List of endpoint info maps of the specified type.
  """
  def list_by_type(type) when type in [:info, :exchange, :subscription] do
    list_endpoints()
    |> Enum.filter(&(&1.type == type))
  end

  @doc """
  Calculate total rate limit cost for a list of endpoints.

  ## Parameters

  - `names` - List of endpoint names

  ## Returns

  Total rate limit cost as integer.

  ## Example

      iex> Hyperliquid.Api.Registry.total_rate_limit_cost(["allMids", "l2Book"])
      4
  """
  def total_rate_limit_cost(names) when is_list(names) do
    names
    |> Enum.map(&get_endpoint_info/1)
    |> Enum.filter(&match?({:ok, _}, &1))
    |> Enum.map(fn {:ok, info} -> info.rate_limit_cost end)
    |> Enum.sum()
  end

  @doc """
  Get endpoint documentation as formatted string.

  ## Parameters

  - `name` - The endpoint name

  ## Returns

  Formatted documentation string or error.
  """
  def docs(name) when is_binary(name) do
    case get_endpoint_info(name) do
      {:ok, info} ->
        """
        Endpoint: #{info.endpoint}
        Type: #{info.type}
        Rate Limit Cost: #{info.rate_limit_cost} (out of 1200/min)

        Description:
        #{if info.doc != "", do: info.doc, else: "No description available"}

        Returns:
        #{if info.returns != "", do: info.returns, else: "No return info available"}

        Parameters:
        #{format_params(info.params, info.optional_params)}

        Module: #{inspect(info.module)}
        """

      {:error, :not_found} ->
        {:error, "Endpoint '#{name}' not found"}
    end
  end

  defp format_params([], []), do: "None"

  defp format_params(required, optional) do
    required_str =
      if required != [] do
        "Required: #{Enum.join(required, ", ")}"
      else
        ""
      end

    optional_str =
      if optional != [] do
        "Optional: #{Enum.join(optional, ", ")}"
      else
        ""
      end

    [required_str, optional_str]
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("\n")
  end

  @doc """
  Print formatted documentation for an endpoint.

  ## Parameters

  - `name` - The endpoint name
  """
  def print_docs(name) do
    case docs(name) do
      {:error, msg} -> IO.puts(msg)
      doc -> IO.puts(doc)
    end
  end

  @doc """
  Returns a summary of rate limits for all endpoints.

  Groups endpoints by their rate limit cost.
  """
  def rate_limit_summary do
    list_endpoints()
    |> Enum.group_by(& &1.rate_limit_cost)
    |> Enum.sort_by(fn {cost, _} -> cost end)
    |> Enum.map(fn {cost, endpoints} ->
      names = Enum.map(endpoints, & &1.endpoint)
      {cost, names}
    end)
  end
end
