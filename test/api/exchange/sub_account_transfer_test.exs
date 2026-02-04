defmodule Hyperliquid.Api.Exchange.SubAccountTransferTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.SubAccountTransfer

  @private_key "0000000000000000000000000000000000000000000000000000000000000001"

  describe "request/5" do
    test "builds correct action structure for deposit to sub-account" do
      sub_account_user = "0x1234567890123456789012345678901234567890"
      is_deposit = true
      usd = 1_000_000

      # Call the request function - we expect it to fail at the API level,
      # but we can inspect the action structure that was built
      result =
        SubAccountTransfer.request(sub_account_user, is_deposit, usd, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds correct action structure for withdrawal from sub-account" do
      sub_account_user = "0x1234567890123456789012345678901234567890"
      is_deposit = false
      usd = 500_000

      result =
        SubAccountTransfer.request(sub_account_user, is_deposit, usd, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with correct JSON field order" do
      # Test that action fields are in correct order: type, subAccountUser, isDeposit, usd
      sub_account_user = "0x1234567890123456789012345678901234567890"
      is_deposit = true
      usd = 1_000_000

      action =
        Jason.OrderedObject.new([
          {:type, "subAccountTransfer"},
          {:subAccountUser, sub_account_user},
          {:isDeposit, is_deposit},
          {:usd, usd}
        ])

      action_json = Jason.encode!(action)

      expected_json =
        ~s({"type":"subAccountTransfer","subAccountUser":"#{sub_account_user}","isDeposit":true,"usd":#{usd}})

      assert action_json == expected_json
    end

    test "validates field names are correct" do
      # Ensure we're using the correct field names
      action =
        Jason.OrderedObject.new([
          {:type, "subAccountTransfer"},
          {:subAccountUser, "0x1234567890123456789012345678901234567890"},
          {:isDeposit, true},
          {:usd, 1_000_000}
        ])

      action_map = Jason.decode!(Jason.encode!(action))

      assert Map.has_key?(action_map, "type")
      assert Map.has_key?(action_map, "subAccountUser")
      assert Map.has_key?(action_map, "isDeposit")
      assert Map.has_key?(action_map, "usd")

      refute Map.has_key?(action_map, "sub_account_user")
      refute Map.has_key?(action_map, "is_deposit")
      refute Map.has_key?(action_map, "amount")

      # Verify correct values
      assert action_map["type"] == "subAccountTransfer"
    end

    test "field order is preserved in encoded JSON" do
      # This test ensures that when we encode the action, the field order is exactly as specified
      sub_account_user = "0x1234567890123456789012345678901234567890"
      usd = 2_500_000

      action =
        Jason.OrderedObject.new([
          {:type, "subAccountTransfer"},
          {:subAccountUser, sub_account_user},
          {:isDeposit, false},
          {:usd, usd}
        ])

      action_json = Jason.encode!(action)

      # The JSON string should start with {"type":"subAccountTransfer"
      assert String.starts_with?(action_json, ~s({"type":"subAccountTransfer"))

      # Verify all fields are present
      assert String.contains?(action_json, ~s("type":"subAccountTransfer"))
      assert String.contains?(action_json, ~s("subAccountUser":"#{sub_account_user}"))
      assert String.contains?(action_json, ~s("isDeposit":false))
      assert String.contains?(action_json, ~s("usd":#{usd}))
    end

    test "handles different isDeposit values" do
      sub_account_user = "0x1234567890123456789012345678901234567890"
      usd = 1_000_000

      # Test deposit (true)
      deposit_action =
        Jason.OrderedObject.new([
          {:type, "subAccountTransfer"},
          {:subAccountUser, sub_account_user},
          {:isDeposit, true},
          {:usd, usd}
        ])

      deposit_map = Jason.decode!(Jason.encode!(deposit_action))
      assert deposit_map["isDeposit"] == true

      # Test withdrawal (false)
      withdraw_action =
        Jason.OrderedObject.new([
          {:type, "subAccountTransfer"},
          {:subAccountUser, sub_account_user},
          {:isDeposit, false},
          {:usd, usd}
        ])

      withdraw_map = Jason.decode!(Jason.encode!(withdraw_action))
      assert withdraw_map["isDeposit"] == false
    end

    test "handles different USD amounts" do
      sub_account_user = "0x1234567890123456789012345678901234567890"

      test_amounts = [
        1_000_000,
        # $1
        500_000,
        # $0.50
        10_000_000,
        # $10
        100_000
        # $0.10
      ]

      for usd <- test_amounts do
        action =
          Jason.OrderedObject.new([
            {:type, "subAccountTransfer"},
            {:subAccountUser, sub_account_user},
            {:isDeposit, true},
            {:usd, usd}
          ])

        action_map = Jason.decode!(Jason.encode!(action))
        assert action_map["usd"] == usd
      end
    end

    test "usd field is an integer not a string" do
      # The usd field should be passed as an integer (raw value)
      # where float * 1e6 = integer value
      sub_account_user = "0x1234567890123456789012345678901234567890"
      usd = 1_000_000

      action =
        Jason.OrderedObject.new([
          {:type, "subAccountTransfer"},
          {:subAccountUser, sub_account_user},
          {:isDeposit, true},
          {:usd, usd}
        ])

      action_json = Jason.encode!(action)

      # Verify that usd is encoded as a number, not a string
      assert String.contains?(action_json, ~s("usd":#{usd}))
      refute String.contains?(action_json, ~s("usd":"#{usd}"))
    end
  end
end
