defmodule Hyperliquid.Api.Exchange do
  @moduledoc """
  Convenience functions for Exchange API endpoints.

  This module provides snake_case wrapper functions that delegate to the
  underlying endpoint modules, improving developer ergonomics.

  ## Usage

      # Direct endpoint call (when available)
      {:ok, result} = Hyperliquid.Api.Exchange.SomeEndpoint.request(...)

      # Convenience wrapper (when DSL is used)
      {:ok, result} = Hyperliquid.Api.Exchange.some_endpoint(...)

  ## Note

  Currently, Exchange endpoints use a different implementation pattern and
  are not yet migrated to the DSL. This module is a placeholder for future
  Exchange endpoint migrations.

  For now, use the existing Exchange modules directly:
  - `Hyperliquid.Api.Exchange.Order`
  - `Hyperliquid.Api.Exchange.Cancel`
  - etc.

  See `Hyperliquid.Api.Registry.list_by_type(:exchange)` for available endpoints.
  """

  # Generate delegated functions for all Exchange endpoints at compile time
  # Currently the list is empty, but this will auto-populate as endpoints migrate to DSL
  require Hyperliquid.Api.DelegationHelper
  Hyperliquid.Api.DelegationHelper.generate_delegated_functions(:exchange)
end
