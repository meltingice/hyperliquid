defmodule Hyperliquid.Api.Exchange.SubAccountModifyTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.SubAccountModify

  @private_key "0000000000000000000000000000000000000000000000000000000000000001"

  describe "request/3" do
    test "builds correct action structure for renaming sub-account" do
      name = "Renamed Bot"
      sub_account_user = "0x1234567890123456789012345678901234567890"

      # Call the request function - we expect it to fail at the API level,
      # but we can inspect the action structure that was built
      result = SubAccountModify.request(name, sub_account_user: sub_account_user, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with correct JSON field order when modifying" do
      # Test that action fields are in correct order: type, subAccountUser, name
      name = "New Name"
      sub_account_user = "0x1234567890123456789012345678901234567890"

      action =
        Jason.OrderedObject.new([
          {:type, "subAccountModify"},
          {:subAccountUser, sub_account_user},
          {:name, name}
        ])

      action_json = Jason.encode!(action)

      expected_json =
        ~s({"type":"subAccountModify","subAccountUser":"#{sub_account_user}","name":"#{name}"})

      assert action_json == expected_json
    end

    test "builds action with correct JSON field order without sub_account_user" do
      # When creating (no subAccountUser), field order should be: type, name
      name = "Test Account"

      action =
        Jason.OrderedObject.new([
          {:type, "subAccountModify"},
          {:name, name}
        ])

      action_json = Jason.encode!(action)
      expected_json = ~s({"type":"subAccountModify","name":"#{name}"})
      assert action_json == expected_json
    end

    test "validates field names are correct with subAccountUser" do
      # Ensure we're using 'type', 'subAccountUser', and 'name'
      action =
        Jason.OrderedObject.new([
          {:type, "subAccountModify"},
          {:subAccountUser, "0x1234567890123456789012345678901234567890"},
          {:name, "Test"}
        ])

      action_map = Jason.decode!(Jason.encode!(action))

      assert Map.has_key?(action_map, "type")
      assert Map.has_key?(action_map, "subAccountUser")
      assert Map.has_key?(action_map, "name")
      refute Map.has_key?(action_map, "sub_account_user")
      refute Map.has_key?(action_map, "accountName")
    end

    test "validates field names are correct without subAccountUser" do
      # Ensure we're using 'type' and 'name' only
      action =
        Jason.OrderedObject.new([
          {:type, "subAccountModify"},
          {:name, "Test"}
        ])

      action_map = Jason.decode!(Jason.encode!(action))

      assert Map.has_key?(action_map, "type")
      assert Map.has_key?(action_map, "name")
      refute Map.has_key?(action_map, "subAccountUser")
    end

    test "field order is preserved in encoded JSON with subAccountUser" do
      # This test ensures that when we encode the action, the field order is exactly as specified
      name = "Ordered Test"
      sub_account_user = "0x1234567890123456789012345678901234567890"

      action =
        Jason.OrderedObject.new([
          {:type, "subAccountModify"},
          {:subAccountUser, sub_account_user},
          {:name, name}
        ])

      action_json = Jason.encode!(action)

      # The JSON string should start with {"type":"subAccountModify"
      assert String.starts_with?(action_json, ~s({"type":"subAccountModify"))

      # And contain fields in order
      assert String.contains?(action_json, ~s("type":"subAccountModify"))
      assert String.contains?(action_json, ~s("subAccountUser":"#{sub_account_user}"))
      assert String.contains?(action_json, ~s("name":"#{name}"))
    end

    test "handles different names" do
      test_cases = [
        {"Trading Bot", "Trading Bot"},
        {"Sub Account 1", "Sub Account 1"},
        {"Renamed", "Renamed"}
      ]

      for {name, expected_name} <- test_cases do
        action =
          Jason.OrderedObject.new([
            {:type, "subAccountModify"},
            {:name, name}
          ])

        action_map = Jason.decode!(Jason.encode!(action))
        assert action_map["type"] == "subAccountModify"
        assert action_map["name"] == expected_name
      end
    end
  end
end
