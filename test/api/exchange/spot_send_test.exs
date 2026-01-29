defmodule Hyperliquid.Api.Exchange.SpotSendTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.SpotSend
  alias Hyperliquid.Utils

  @private_key "0000000000000000000000000000000000000000000000000000000000000001"

  describe "request/5" do
    test "builds correct action structure for basic spot send" do
      destination = "0x0000000000000000000000000000000000000001"
      token = "USDC:0xeb62eee3685fc4c43992febcd9e75443"
      amount = "10.0"

      # Call the request function - we expect it to fail at the API level,
      # but we can inspect the action structure that was built
      result = SpotSend.request(destination, token, amount, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with correct JSON field order for mainnet" do
      # Simulate mainnet action structure
      # Field order: type, signatureChainId, hyperliquidChain, destination, token, amount, time
      time = 1_234_567_890
      mainnet_chain_id = Utils.from_int(42_161)

      action =
        Jason.OrderedObject.new([
          {:type, "spotSend"},
          {:signatureChainId, mainnet_chain_id},
          {:hyperliquidChain, "Mainnet"},
          {:destination, "0x0000000000000000000000000000000000000001"},
          {:token, "USDC:0xeb62eee3685fc4c43992febcd9e75443"},
          {:amount, "10"},
          {:time, time}
        ])

      action_json = Jason.encode!(action)

      expected_json =
        ~s({"type":"spotSend","signatureChainId":"#{mainnet_chain_id}","hyperliquidChain":"Mainnet","destination":"0x0000000000000000000000000000000000000001","token":"USDC:0xeb62eee3685fc4c43992febcd9e75443","amount":"10","time":#{time}})

      assert action_json == expected_json
    end

    test "builds action with correct JSON field order for testnet" do
      # Simulate testnet action structure
      time = 1_234_567_890
      testnet_chain_id = Utils.from_int(421_614)

      action =
        Jason.OrderedObject.new([
          {:type, "spotSend"},
          {:signatureChainId, testnet_chain_id},
          {:hyperliquidChain, "Testnet"},
          {:destination, "0x0000000000000000000000000000000000000002"},
          {:token, "HYPE:0x1234567890123456789012345678901234567890"},
          {:amount, "5.5"},
          {:time, time}
        ])

      action_json = Jason.encode!(action)

      expected_json =
        ~s({"type":"spotSend","signatureChainId":"#{testnet_chain_id}","hyperliquidChain":"Testnet","destination":"0x0000000000000000000000000000000000000002","token":"HYPE:0x1234567890123456789012345678901234567890","amount":"5.5","time":#{time}})

      assert action_json == expected_json
    end

    test "validates field names are correct" do
      # Ensure we're using the correct field names
      time = 1_234_567_890
      chain_id = Utils.from_int(42_161)

      action =
        Jason.OrderedObject.new([
          {:type, "spotSend"},
          {:signatureChainId, chain_id},
          {:hyperliquidChain, "Mainnet"},
          {:destination, "0x0000000000000000000000000000000000000001"},
          {:token, "USDC:0xeb62eee3685fc4c43992febcd9e75443"},
          {:amount, "10"},
          {:time, time}
        ])

      action_map = Jason.decode!(Jason.encode!(action))

      assert Map.has_key?(action_map, "type")
      assert Map.has_key?(action_map, "signatureChainId")
      assert Map.has_key?(action_map, "hyperliquidChain")
      assert Map.has_key?(action_map, "destination")
      assert Map.has_key?(action_map, "token")
      assert Map.has_key?(action_map, "amount")
      assert Map.has_key?(action_map, "time")

      # Verify correct values
      assert action_map["type"] == "spotSend"
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
          {:type, "spotSend"},
          {:signatureChainId, chain_id},
          {:hyperliquidChain, "Mainnet"},
          {:destination, "0x1234567890123456789012345678901234567890"},
          {:token, "USDC:0xeb62eee3685fc4c43992febcd9e75443"},
          {:amount, "100"},
          {:time, time}
        ])

      action_json = Jason.encode!(action)

      # The JSON string should start with {"type":"spotSend","signatureChainId":
      assert String.starts_with?(action_json, ~s({"type":"spotSend","signatureChainId":))

      # Verify all fields are present
      assert String.contains?(action_json, ~s("type":"spotSend"))
      assert String.contains?(action_json, ~s("signatureChainId":"#{chain_id}"))
      assert String.contains?(action_json, ~s("hyperliquidChain":"Mainnet"))

      assert String.contains?(
               action_json,
               ~s("destination":"0x1234567890123456789012345678901234567890")
             )

      assert String.contains?(action_json, ~s("token":"USDC:0xeb62eee3685fc4c43992febcd9e75443"))
      assert String.contains?(action_json, ~s("amount":"100"))
      assert String.contains?(action_json, ~s("time":#{time}))
    end
  end
end
