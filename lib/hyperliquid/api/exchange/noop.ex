defmodule Hyperliquid.Api.Exchange.Noop do
  @moduledoc """
  Send a no-op (heartbeat) to keep connection alive.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint

  ## Usage

      {:ok, result} = Noop.request(private_key)
  """

  use Hyperliquid.Api.ExchangeEndpoint,
    action_type: "noop",
    signing: :l1,
    doc: "Send a no-op heartbeat to keep connection alive",
    returns: "Success/error response from exchange",
    params: [:private_key],
    optional_params: [:vault_address],
    rate_limit_cost: 1
end
