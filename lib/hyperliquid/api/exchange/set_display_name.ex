defmodule Hyperliquid.Api.Exchange.SetDisplayName do
  @moduledoc """
  Set display name for user account.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint

  ## Usage

      {:ok, result} = SetDisplayName.request(private_key, "MyTrader")
  """

  use Hyperliquid.Api.ExchangeEndpoint,
    action_type: "setDisplayName",
    signing: :l1,
    doc: "Set display name for user account",
    returns: "Success/error response from exchange",
    params: [:display_name],
    optional_params: [:private_key, :vault_address],
    rate_limit_cost: 1

  @doc false
  def build_action(display_name) do
    %{type: "setDisplayName", displayName: display_name}
  end
end
