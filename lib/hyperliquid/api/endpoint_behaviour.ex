defmodule Hyperliquid.Api.EndpointBehaviour do
  @moduledoc """
  Behavior defining the contract for API endpoint modules.

  This behavior ensures all endpoint modules provide consistent introspection
  metadata through the `__endpoint_info__/0` callback.

  ## Purpose

  1. **Registry Discovery** - The `Hyperliquid.Api.Registry` uses this callback
     to discover and introspect endpoints for documentation generation and
     rate limit calculation.

  2. **DelegationHelper Generation** - The `Hyperliquid.Api.DelegationHelper`
     uses endpoint metadata to generate snake_case wrapper functions with
     correct signatures, documentation, and typespecs.

  3. **Contract Enforcement** - Compile-time verification that endpoint modules
     provide all required metadata.

  ## Usage

  Endpoint modules implementing this behavior must define `__endpoint_info__/0`:

      defmodule Hyperliquid.Api.Info.AllMids do
        @behaviour Hyperliquid.Api.EndpointBehaviour

        @impl true
        def __endpoint_info__ do
          %{
            endpoint: "allMids",
            type: :info,
            rate_limit_cost: 2,
            params: [],
            optional_params: [],
            doc: "Get all mid prices for all tradeable assets",
            returns: "Map of asset symbols to mid prices",
            module: __MODULE__
          }
        end
      end

  ## Note

  The Endpoint DSL (`Hyperliquid.Api.Endpoint`) automatically generates the
  `__endpoint_info__/0` callback and adds this behavior declaration. Endpoint
  modules using the DSL do not need to manually implement this behavior.
  """

  @typedoc """
  Metadata map returned by `__endpoint_info__/0`.

  ## Fields

  - `:endpoint` - API endpoint name as string (e.g., "allMids", "l2Book")
  - `:type` - Endpoint type atom (`:info`, `:exchange`, `:subscription`)
  - `:rate_limit_cost` - Weight against Hyperliquid's rate limit (1200/min)
  - `:params` - List of required parameter atoms
  - `:optional_params` - List of optional parameter atoms
  - `:doc` - Human-readable description of the endpoint
  - `:returns` - Description of what the endpoint returns
  - `:module` - The endpoint module itself
  """
  @type endpoint_info :: %{
          endpoint: String.t(),
          type: atom(),
          rate_limit_cost: non_neg_integer(),
          params: [atom()],
          optional_params: [atom()],
          doc: String.t(),
          returns: String.t(),
          module: module()
        }

  @doc """
  Returns endpoint metadata for introspection.

  This callback is used by:
  - `Hyperliquid.Api.Registry` for endpoint discovery and documentation
  - `Hyperliquid.Api.DelegationHelper` for generating wrapper functions

  ## Returns

  An `endpoint_info` map containing all metadata about the endpoint.
  """
  @callback __endpoint_info__() :: endpoint_info()
end
