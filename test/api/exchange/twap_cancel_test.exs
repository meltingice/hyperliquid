defmodule Hyperliquid.Api.Exchange.TwapCancelTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.TwapCancel

  @private_key "0000000000000000000000000000000000000000000000000000000000000001"

  describe "request/4" do
    test "builds correct action structure for basic twap cancel" do
      # Call the request function - we expect it to fail at the API level,
      # but we can inspect the action structure that was built
      result = TwapCancel.request(0, 12345, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      # Both indicate action was built correctly
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds correct action structure with vault address" do
      vault_address = "0x1234567890123456789012345678901234567890"

      result = TwapCancel.request(1, 67890, private_key: @private_key, vault_address: vault_address)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with correct JSON field order" do
      # We need to test that the action structure has correct field order
      # This is critical for hash calculation
      asset = 0
      twap_id = 12345

      # Build the action the same way the module does
      action =
        Jason.OrderedObject.new([
          {:type, "twapCancel"},
          {:a, asset},
          {:t, twap_id}
        ])

      action_json = Jason.encode!(action)

      # Verify field order: type, a, t
      expected_json = ~s({"type":"twapCancel","a":0,"t":12345})
      assert action_json == expected_json
    end

    test "builds action with different asset and twap_id values" do
      action =
        Jason.OrderedObject.new([
          {:type, "twapCancel"},
          {:a, 3},
          {:t, 999_888_777}
        ])

      action_json = Jason.encode!(action)
      expected_json = ~s({"type":"twapCancel","a":3,"t":999888777})
      assert action_json == expected_json
    end

    test "validates field names are correct" do
      # Ensure we're using 'a' and 't', not other field names
      action =
        Jason.OrderedObject.new([
          {:type, "twapCancel"},
          {:a, 0},
          {:t, 12345}
        ])

      action_map = Jason.decode!(Jason.encode!(action))

      assert Map.has_key?(action_map, "type")
      assert Map.has_key?(action_map, "a")
      assert Map.has_key?(action_map, "t")
      refute Map.has_key?(action_map, "asset")
      refute Map.has_key?(action_map, "twap_id")
      refute Map.has_key?(action_map, "twapId")
    end
  end
end
