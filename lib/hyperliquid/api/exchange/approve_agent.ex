defmodule Hyperliquid.Api.Exchange.ApproveAgent do
  @moduledoc """
  Approve an agent to trade on behalf of your account.

  Agents are sub-keys that can be granted trading permissions without exposing
  your main private key.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
  """

  alias Hyperliquid.{Config, Signer, Utils}
  alias Hyperliquid.Transport.Http

  # ===================== Types =====================

  @type approve_opts :: [
          agent_name: String.t()
        ]

  @type approve_response :: %{
          status: String.t(),
          response: map()
        }

  # ===================== Request Functions =====================

  @doc """
  Approve an agent to trade on your behalf.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `agent_address`: Address of the agent to approve (0x...)
    - `opts`: Optional parameters

  ## Options
    - `:agent_name` - Human-readable name for the agent

  ## Returns
    - `{:ok, response}` - Approval result
    - `{:error, term()}` - Error details

  ## Examples

      # Approve agent with default name
      {:ok, result} = ApproveAgent.approve(private_key, "0x1234...")

      # Approve agent with custom name
      {:ok, result} = ApproveAgent.approve(private_key, "0x1234...", agent_name: "Trading Bot")
  """
  @spec approve(String.t(), String.t(), approve_opts()) ::
          {:ok, approve_response()} | {:error, term()}
  def approve(private_key, agent_address, opts \\ []) do
    agent_name = Keyword.get(opts, :agent_name)
    nonce = generate_nonce()

    # Normalize address to checksum format
    agent_address = Signer.to_checksum_address(agent_address)

    with {:ok, signature} <- sign_approve(private_key, agent_address, agent_name, nonce) do
      action = build_action(agent_address, agent_name, nonce)
      # L1 actions don't use expires_after
      Http.exchange_request(action, signature, nonce, nil, nil)
    end
  end

  # ===================== Action Building =====================

  defp build_action(agent_address, agent_name, nonce) do
    is_mainnet = Config.mainnet?()

    action = %{
      type: "approveAgent",
      hyperliquidChain: if(is_mainnet, do: "Mainnet", else: "Testnet"),
      signatureChainId: Utils.from_int(42_161),
      agentAddress: agent_address,
      nonce: nonce
    }

    if agent_name do
      Map.put(action, :agentName, agent_name)
    else
      action
    end
  end

  # ===================== Signing =====================

  defp sign_approve(private_key, agent_address, agent_name, nonce) do
    is_mainnet = Config.mainnet?()

    case Signer.sign_approve_agent(private_key, agent_address, agent_name, nonce, is_mainnet) do
      %{"r" => r, "s" => s, "v" => v} ->
        {:ok, %{r: r, s: s, v: v}}

      error ->
        {:error, {:signing_error, error}}
    end
  end

  defp generate_nonce do
    System.system_time(:millisecond)
  end
end
