defmodule Hyperliquid.Api.Stats do
  @moduledoc """
  Convenience functions for Stats API endpoints.

  This module provides snake_case wrapper functions that delegate to the
  underlying endpoint modules, improving developer ergonomics.

  ## Usage

      # Direct endpoint call (still supported)
      {:ok, result} = Hyperliquid.Api.Stats.Leaderboard.request()

      # Convenience wrapper
      {:ok, result} = Hyperliquid.Api.Stats.leaderboard()

  See `Hyperliquid.Api.Registry.list_by_type(:stats)` for all available endpoints.
  """

  # Generate delegated functions for all Stats endpoints at compile time
  require Hyperliquid.Api.DelegationHelper
  Hyperliquid.Api.DelegationHelper.generate_delegated_functions(:stats)
end
