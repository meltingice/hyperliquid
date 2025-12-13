defmodule Hyperliquid.Api.Exchange.SetDisplayName do
  @moduledoc """
  Set your account display name.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint

  ## Usage

      {:ok, result} = SetDisplayName.request(private_key, "MyTrader")
  """

  use Hyperliquid.Api.ExchangeEndpoint,
    action_type: "setDisplayName",
    signing: :l1

  @doc false
  def build_action(display_name) do
    %{type: "setDisplayName", displayName: display_name}
  end
end
