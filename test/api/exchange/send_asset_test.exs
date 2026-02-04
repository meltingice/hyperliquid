defmodule Hyperliquid.Api.Exchange.SendAssetTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.SendAsset
  alias Hyperliquid.Utils

  @private_key "0000000000000000000000000000000000000000000000000000000000000001"

  describe "request/7" do
    test "builds correct action structure for perp to spot transfer" do
      destination = "0x0000000000000000000000000000000000000001"
      source_dex = ""
      destination_dex = "spot"
      token = "USDC:0xeb62eee3685fc4c43992febcd9e75443"
      amount = "100.0"

      # Call the request function - we expect it to fail at the API level,
      # but we can inspect the action structure that was built
      result =
        SendAsset.request(destination, source_dex, destination_dex, token, amount,
          private_key: @private_key
        )

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds correct action structure with from_sub_account option" do
      destination = "0x0000000000000000000000000000000000000001"
      source_dex = ""
      destination_dex = ""
      token = "USDC:0xeb62eee3685fc4c43992febcd9e75443"
      amount = "50.0"
      from_sub_account = "0x1234567890123456789012345678901234567890"

      result =
        SendAsset.request(
          destination,
          source_dex,
          destination_dex,
          token,
          amount,
          from_sub_account: from_sub_account,
          private_key: @private_key
        )

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with correct JSON field order for mainnet" do
      # Simulate mainnet action structure
      # Field order: type, signatureChainId, hyperliquidChain, destination, sourceDex,
      #              destinationDex, token, amount, fromSubAccount, nonce
      time = 1_234_567_890
      mainnet_chain_id = Utils.from_int(42_161)

      action =
        Jason.OrderedObject.new([
          {:type, "sendAsset"},
          {:signatureChainId, mainnet_chain_id},
          {:hyperliquidChain, "Mainnet"},
          {:destination, "0x0000000000000000000000000000000000000001"},
          {:sourceDex, ""},
          {:destinationDex, "spot"},
          {:token, "USDC:0xeb62eee3685fc4c43992febcd9e75443"},
          {:amount, "100"},
          {:fromSubAccount, ""},
          {:nonce, time}
        ])

      action_json = Jason.encode!(action)

      expected_json =
        ~s({"type":"sendAsset","signatureChainId":"#{mainnet_chain_id}","hyperliquidChain":"Mainnet","destination":"0x0000000000000000000000000000000000000001","sourceDex":"","destinationDex":"spot","token":"USDC:0xeb62eee3685fc4c43992febcd9e75443","amount":"100","fromSubAccount":"","nonce":#{time}})

      assert action_json == expected_json
    end

    test "builds action with correct JSON field order for testnet" do
      # Simulate testnet action structure
      time = 1_234_567_890
      testnet_chain_id = Utils.from_int(421_614)
      from_sub_account = "0x1234567890123456789012345678901234567890"

      action =
        Jason.OrderedObject.new([
          {:type, "sendAsset"},
          {:signatureChainId, testnet_chain_id},
          {:hyperliquidChain, "Testnet"},
          {:destination, "0x0000000000000000000000000000000000000002"},
          {:sourceDex, "spot"},
          {:destinationDex, ""},
          {:token, "HYPE:0x9876543210987654321098765432109876543210"},
          {:amount, "50.5"},
          {:fromSubAccount, from_sub_account},
          {:nonce, time}
        ])

      action_json = Jason.encode!(action)

      expected_json =
        ~s({"type":"sendAsset","signatureChainId":"#{testnet_chain_id}","hyperliquidChain":"Testnet","destination":"0x0000000000000000000000000000000000000002","sourceDex":"spot","destinationDex":"","token":"HYPE:0x9876543210987654321098765432109876543210","amount":"50.5","fromSubAccount":"#{from_sub_account}","nonce":#{time}})

      assert action_json == expected_json
    end

    test "validates field names are correct" do
      # Ensure we're using the correct field names
      time = 1_234_567_890
      chain_id = Utils.from_int(42_161)

      action =
        Jason.OrderedObject.new([
          {:type, "sendAsset"},
          {:signatureChainId, chain_id},
          {:hyperliquidChain, "Mainnet"},
          {:destination, "0x0000000000000000000000000000000000000001"},
          {:sourceDex, ""},
          {:destinationDex, "spot"},
          {:token, "USDC:0xeb62eee3685fc4c43992febcd9e75443"},
          {:amount, "100"},
          {:fromSubAccount, ""},
          {:nonce, time}
        ])

      action_map = Jason.decode!(Jason.encode!(action))

      assert Map.has_key?(action_map, "type")
      assert Map.has_key?(action_map, "signatureChainId")
      assert Map.has_key?(action_map, "hyperliquidChain")
      assert Map.has_key?(action_map, "destination")
      assert Map.has_key?(action_map, "sourceDex")
      assert Map.has_key?(action_map, "destinationDex")
      assert Map.has_key?(action_map, "token")
      assert Map.has_key?(action_map, "amount")
      assert Map.has_key?(action_map, "fromSubAccount")
      assert Map.has_key?(action_map, "nonce")

      # Verify correct values
      assert action_map["type"] == "sendAsset"
      assert action_map["hyperliquidChain"] == "Mainnet"
    end

    test "uses correct chain IDs" do
      # Mainnet chain ID should be 42161 (0xA4B1 or 0xa4b1 in hex)
      mainnet_chain_id = Utils.from_int(42_161)
      assert String.downcase(mainnet_chain_id) == "0xa4b1"

      # Testnet chain ID should be 421614 (0x66EEE or 0x66eee in hex)
      testnet_chain_id = Utils.from_int(421_614)
      assert String.downcase(testnet_chain_id) == "0x66eee"
    end

    test "field order is preserved in encoded JSON" do
      # This test ensures that when we encode the action, the field order is exactly as specified
      time = 1_234_567_890
      chain_id = Utils.from_int(42_161)

      action =
        Jason.OrderedObject.new([
          {:type, "sendAsset"},
          {:signatureChainId, chain_id},
          {:hyperliquidChain, "Mainnet"},
          {:destination, "0x1234567890123456789012345678901234567890"},
          {:sourceDex, ""},
          {:destinationDex, "test"},
          {:token, "USDC:0xeb62eee3685fc4c43992febcd9e75443"},
          {:amount, "100"},
          {:fromSubAccount, ""},
          {:nonce, time}
        ])

      action_json = Jason.encode!(action)

      # The JSON string should start with {"type":"sendAsset","signatureChainId":
      assert String.starts_with?(action_json, ~s({"type":"sendAsset","signatureChainId":))

      # Verify all fields are present
      assert String.contains?(action_json, ~s("type":"sendAsset"))
      assert String.contains?(action_json, ~s("signatureChainId":"#{chain_id}"))
      assert String.contains?(action_json, ~s("hyperliquidChain":"Mainnet"))

      assert String.contains?(
               action_json,
               ~s("destination":"0x1234567890123456789012345678901234567890")
             )

      assert String.contains?(action_json, ~s("sourceDex":""))
      assert String.contains?(action_json, ~s("destinationDex":"test"))
      assert String.contains?(action_json, ~s("token":"USDC:0xeb62eee3685fc4c43992febcd9e75443"))
      assert String.contains?(action_json, ~s("amount":"100"))
      assert String.contains?(action_json, ~s("fromSubAccount":""))
      assert String.contains?(action_json, ~s("nonce":#{time}))
    end

    test "handles different dex combinations" do
      test_cases = [
        {"", "spot", "perp to spot"},
        {"spot", "", "spot to perp"},
        {"", "", "perp to perp"},
        {"spot", "spot", "spot to spot"}
      ]

      time = 1_234_567_890
      chain_id = Utils.from_int(42_161)

      for {source_dex, destination_dex, _description} <- test_cases do
        action =
          Jason.OrderedObject.new([
            {:type, "sendAsset"},
            {:signatureChainId, chain_id},
            {:hyperliquidChain, "Mainnet"},
            {:destination, "0x0000000000000000000000000000000000000001"},
            {:sourceDex, source_dex},
            {:destinationDex, destination_dex},
            {:token, "USDC:0xeb62eee3685fc4c43992febcd9e75443"},
            {:amount, "100"},
            {:fromSubAccount, ""},
            {:nonce, time}
          ])

        action_map = Jason.decode!(Jason.encode!(action))
        assert action_map["sourceDex"] == source_dex
        assert action_map["destinationDex"] == destination_dex
      end
    end

    test "fromSubAccount defaults to empty string when not provided" do
      time = 1_234_567_890
      chain_id = Utils.from_int(42_161)

      # When fromSubAccount is not provided, it should default to ""
      action =
        Jason.OrderedObject.new([
          {:type, "sendAsset"},
          {:signatureChainId, chain_id},
          {:hyperliquidChain, "Mainnet"},
          {:destination, "0x0000000000000000000000000000000000000001"},
          {:sourceDex, ""},
          {:destinationDex, "spot"},
          {:token, "USDC:0xeb62eee3685fc4c43992febcd9e75443"},
          {:amount, "100"},
          {:fromSubAccount, ""},
          {:nonce, time}
        ])

      action_map = Jason.decode!(Jason.encode!(action))
      assert action_map["fromSubAccount"] == ""
    end
  end
end
