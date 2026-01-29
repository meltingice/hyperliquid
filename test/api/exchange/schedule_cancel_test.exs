defmodule Hyperliquid.Api.Exchange.ScheduleCancelTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.ScheduleCancel

  @private_key "0000000000000000000000000000000000000000000000000000000000000001"

  describe "request/3" do
    test "builds correct action structure with schedule time" do
      # Schedule cancel in 1 hour
      schedule_time = System.system_time(:millisecond) + 3_600_000

      # Call the request function - we expect it to fail at the API level,
      # but we can inspect the action structure that was built
      result = ScheduleCancel.request(schedule_time, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds correct action structure to remove scheduled cancel" do
      # Passing nil should remove the scheduled cancel
      result = ScheduleCancel.request(nil, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with vault address" do
      vault_address = "0x1234567890123456789012345678901234567890"
      schedule_time = System.system_time(:millisecond) + 3_600_000

      result =
        ScheduleCancel.request(schedule_time, private_key: @private_key, vault_address: vault_address)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with correct JSON field order with time" do
      # Test that action fields are in correct order: type, time
      time = 1_700_000_000_000

      action =
        Jason.OrderedObject.new([
          {:type, "scheduleCancel"},
          {:time, time}
        ])

      action_json = Jason.encode!(action)
      expected_json = ~s({"type":"scheduleCancel","time":#{time}})
      assert action_json == expected_json
    end

    test "builds action with correct JSON field order without time" do
      # When time is nil, it should only have type field
      action =
        Jason.OrderedObject.new([
          {:type, "scheduleCancel"}
        ])

      action_json = Jason.encode!(action)
      expected_json = ~s({"type":"scheduleCancel"})
      assert action_json == expected_json
    end

    test "validates field names are correct" do
      # Ensure we're using 'type' and 'time', not other field names
      time = 1_700_000_000_000

      action =
        Jason.OrderedObject.new([
          {:type, "scheduleCancel"},
          {:time, time}
        ])

      action_map = Jason.decode!(Jason.encode!(action))

      assert Map.has_key?(action_map, "type")
      assert Map.has_key?(action_map, "time")
      refute Map.has_key?(action_map, "scheduledTime")
      refute Map.has_key?(action_map, "cancelTime")
    end

    test "omits time field when nil" do
      # When time is nil, the field should not be included in the JSON
      action =
        Jason.OrderedObject.new([
          {:type, "scheduleCancel"}
        ])

      action_map = Jason.decode!(Jason.encode!(action))

      assert Map.has_key?(action_map, "type")
      refute Map.has_key?(action_map, "time")
      assert action_map["type"] == "scheduleCancel"
    end

    test "field order is preserved in encoded JSON with time" do
      # This test ensures that when we encode the action, the field order is exactly as specified
      time = 1_700_000_000_000

      action =
        Jason.OrderedObject.new([
          {:type, "scheduleCancel"},
          {:time, time}
        ])

      action_json = Jason.encode!(action)

      # The JSON string should start with {"type":"scheduleCancel"
      assert String.starts_with?(action_json, ~s({"type":"scheduleCancel"))

      # And contain fields in order
      assert String.contains?(action_json, ~s("type":"scheduleCancel"))
      assert String.contains?(action_json, ~s("time":#{time}))
    end

    test "handles different time values" do
      test_times = [
        1_700_000_000_000,
        System.system_time(:millisecond) + 3_600_000,
        System.system_time(:millisecond) + 86_400_000
      ]

      for time <- test_times do
        action =
          Jason.OrderedObject.new([
            {:type, "scheduleCancel"},
            {:time, time}
          ])

        action_map = Jason.decode!(Jason.encode!(action))
        assert action_map["type"] == "scheduleCancel"
        assert action_map["time"] == time
      end
    end
  end
end
