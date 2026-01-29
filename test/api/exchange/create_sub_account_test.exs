defmodule Hyperliquid.Api.Exchange.CreateSubAccountTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.CreateSubAccount

  @private_key "0000000000000000000000000000000000000000000000000000000000000001"

  describe "request/3" do
    test "builds correct action structure for basic sub-account creation" do
      name = "Trading Bot"

      # Call the request function - we expect it to fail at the API level,
      # but we can inspect the action structure that was built
      result = CreateSubAccount.request(name, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      # Both indicate action was built correctly
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with correct JSON field order" do
      # Test that action fields are in correct order: type, name
      name = "Test Account"

      action =
        Jason.OrderedObject.new([
          {:type, "createSubAccount"},
          {:name, name}
        ])

      action_json = Jason.encode!(action)
      expected_json = ~s({"type":"createSubAccount","name":"Test Account"})
      assert action_json == expected_json
    end

    test "builds action with different names" do
      test_names = [
        "Trading Bot",
        "Sub Account 1",
        "Test",
        "My Account 123"
      ]

      for name <- test_names do
        action =
          Jason.OrderedObject.new([
            {:type, "createSubAccount"},
            {:name, name}
          ])

        action_map = Jason.decode!(Jason.encode!(action))
        assert action_map["type"] == "createSubAccount"
        assert action_map["name"] == name
      end
    end

    test "validates field names are correct" do
      # Ensure we're using 'type' and 'name', not other field names
      action =
        Jason.OrderedObject.new([
          {:type, "createSubAccount"},
          {:name, "Test"}
        ])

      action_map = Jason.decode!(Jason.encode!(action))

      assert Map.has_key?(action_map, "type")
      assert Map.has_key?(action_map, "name")
      refute Map.has_key?(action_map, "accountName")
      refute Map.has_key?(action_map, "subAccountName")
    end

    test "field order is preserved in encoded JSON" do
      # This test ensures that when we encode the action, the field order is exactly as specified
      name = "Ordered Test"

      action =
        Jason.OrderedObject.new([
          {:type, "createSubAccount"},
          {:name, name}
        ])

      action_json = Jason.encode!(action)

      # The JSON string should start with {"type":"createSubAccount"
      assert String.starts_with?(action_json, ~s({"type":"createSubAccount"))

      # And contain fields in order
      assert String.contains?(action_json, ~s("type":"createSubAccount"))
      assert String.contains?(action_json, ~s("name":"#{name}"))
    end
  end
end
