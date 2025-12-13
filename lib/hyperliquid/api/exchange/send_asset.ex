defmodule Hyperliquid.Api.Exchange.SendAsset do
  @moduledoc """
  Transfer tokens between different perp DEXs, spot balance, users, and/or sub-accounts.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint#send-asset
  """

  alias Hyperliquid.{Config, Signer, Utils}
  alias Hyperliquid.Transport.Http

  @doc """
  Transfer tokens between different perp DEXs, spot balance, users, and/or sub-accounts.

  ## Parameters
    - `private_key`: Private key for signing (hex string)
    - `destination`: Destination address
    - `source_dex`: Source DEX ("" for default USDC perp DEX, "spot" for spot)
    - `destination_dex`: Destination DEX ("" for default USDC perp DEX, "spot" for spot)
    - `token`: Token identifier (e.g., "USDC:0xeb62eee3685fc4c43992febcd9e75443")
    - `amount`: Amount to send as string (not in wei)
    - `opts`: Optional parameters

  ## Options
    - `:from_sub_account` - Source sub-account address ("" for main account, default: "")

  ## Returns
    - `{:ok, response}` - Transfer result
    - `{:error, term()}` - Error details

  ## Examples

      # Transfer from perp to spot
      {:ok, result} = SendAsset.request(
        private_key,
        "0x...",
        "",
        "spot",
        "USDC:0xeb62eee3685fc4c43992febcd9e75443",
        "100.0"
      )

      # Transfer from sub-account
      {:ok, result} = SendAsset.request(
        private_key,
        "0x...",
        "",
        "",
        "USDC:0xeb62eee3685fc4c43992febcd9e75443",
        "50.0",
        from_sub_account: "0x..."
      )
  """
  def request(
        private_key,
        destination,
        source_dex,
        destination_dex,
        token,
        amount,
        opts \\ []
      ) do
    time = generate_nonce()
    is_mainnet = Config.mainnet?()
    from_sub_account = Keyword.get(opts, :from_sub_account, "")

    sig =
      sign_send_asset(
        private_key,
        destination,
        source_dex,
        destination_dex,
        token,
        amount,
        from_sub_account,
        time,
        is_mainnet
      )

    # IMPORTANT: Use OrderedObject for correct field order in hash calculation
    # Field order: type, signatureChainId, hyperliquidChain, destination, sourceDex,
    #              destinationDex, token, amount, fromSubAccount, nonce
    action =
      Jason.OrderedObject.new([
        {:type, "sendAsset"},
        {:signatureChainId, signature_chain_id(is_mainnet)},
        {:hyperliquidChain, if(is_mainnet, do: "Mainnet", else: "Testnet")},
        {:destination, destination},
        {:sourceDex, source_dex},
        {:destinationDex, destination_dex},
        {:token, token},
        {:amount, amount},
        {:fromSubAccount, from_sub_account},
        {:nonce, time}
      ])

    signature = %{r: sig["r"], s: sig["s"], v: sig["v"]}

    Http.user_signed_request(action, signature, time, opts)
  end

  defp sign_send_asset(
         private_key,
         destination,
         source_dex,
         destination_dex,
         token,
         amount,
         from_sub_account,
         nonce,
         is_mainnet
       ) do
    # EIP-712 domain
    domain = %{
      name: "Exchange",
      version: "1",
      chainId: if(is_mainnet, do: 42_161, else: 421_614),
      verifyingContract: "0x0000000000000000000000000000000000000000"
    }

    # EIP-712 types for SendAsset
    types = %{
      "EIP712Domain" => [
        %{name: "name", type: "string"},
        %{name: "version", type: "string"},
        %{name: "chainId", type: "uint256"},
        %{name: "verifyingContract", type: "address"}
      ],
      "HyperliquidTransaction:SendAsset" => [
        %{name: "hyperliquidChain", type: "string"},
        %{name: "destination", type: "string"},
        %{name: "sourceDex", type: "string"},
        %{name: "destinationDex", type: "string"},
        %{name: "token", type: "string"},
        %{name: "amount", type: "string"},
        %{name: "fromSubAccount", type: "string"},
        %{name: "nonce", type: "uint64"}
      ]
    }

    # Message to sign
    message = %{
      hyperliquidChain: if(is_mainnet, do: "Mainnet", else: "Testnet"),
      destination: destination,
      sourceDex: source_dex,
      destinationDex: destination_dex,
      token: token,
      amount: amount,
      fromSubAccount: from_sub_account,
      nonce: nonce
    }

    # Convert to JSON for signing
    domain_json = Jason.encode!(domain)
    types_json = Jason.encode!(types)
    message_json = Jason.encode!(message)
    primary_type = "HyperliquidTransaction:SendAsset"

    Signer.sign_typed_data(private_key, domain_json, types_json, message_json, primary_type)
  end

  defp signature_chain_id(true), do: Utils.from_int(42_161)
  defp signature_chain_id(false), do: Utils.from_int(421_614)

  defp generate_nonce do
    System.system_time(:millisecond)
  end
end
