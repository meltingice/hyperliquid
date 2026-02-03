defmodule Hyperliquid.Api.Explorer do
  @moduledoc """
  Convenience functions for Explorer API endpoints.

  This module provides snake_case wrapper functions that delegate to the
  underlying endpoint modules, improving developer ergonomics.

  ## Usage

      # Direct endpoint call (still supported)
      {:ok, result} = Hyperliquid.Api.Explorer.BlockDetails.request(height: 12345)

      # Convenience wrapper
      {:ok, result} = Hyperliquid.Api.Explorer.block_details(12345)

  See `Hyperliquid.Api.Registry.list_by_type(:explorer)` for all available endpoints.
  """

  # Generate delegated functions for all Explorer endpoints at compile time
  require Hyperliquid.Api.DelegationHelper
  Hyperliquid.Api.DelegationHelper.generate_delegated_functions(:explorer)
end
