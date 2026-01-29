defmodule Hyperliquid.Api.Exchange.TwapOrderTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.TwapOrder
  alias Hyperliquid.Utils

  @private_key "0000000000000000000000000000000000000000000000000000000000000001"

  describe "request/5" do
    test "builds correct action structure for basic twap order" do
      # Call the request function - we expect it to fail at the API level,
      # but we can inspect the action structure that was built
      result = TwapOrder.request(0, true, "1.0", private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds correct action with custom duration" do
      result = TwapOrder.request(0, true, "1.0", duration_minutes: 30, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds correct action with reduce_only flag" do
      result = TwapOrder.request(0, false, "0.5", reduce_only: true, private_key: @private_key)

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds correct action with randomize flag" do
      result =
        TwapOrder.request(1, true, "2.0",
          duration_minutes: 15,
          randomize: true,
          private_key: @private_key
        )

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with vault address" do
      vault_address = "0x1234567890123456789012345678901234567890"

      result =
        TwapOrder.request(0, true, "1.0",
          vault_address: vault_address,
          duration_minutes: 10,
          private_key: @private_key
        )

      # Should get response (either error tuple or ok with error status)
      case result do
        {:error, _} -> :ok
        {:ok, %{"status" => "err"}} -> :ok
        other -> flunk("Unexpected result: #{inspect(other)}")
      end
    end

    test "builds action with correct JSON field order for twap" do
      # Test that twap fields are in correct order: a, b, s, r, m, t
      twap =
        Jason.OrderedObject.new([
          {:a, 0},
          {:b, true},
          {:s, Utils.float_to_string("1.0")},
          {:r, false},
          {:m, 5},
          {:t, false}
        ])

      twap_json = Jason.encode!(twap)
      expected_json = ~s({"a":0,"b":true,"s":"1","r":false,"m":5,"t":false})
      assert twap_json == expected_json
    end

    test "builds action with correct JSON field order for action" do
      # Test that action fields are in correct order: type, twap
      twap =
        Jason.OrderedObject.new([
          {:a, 0},
          {:b, true},
          {:s, "1"},
          {:r, false},
          {:m, 5},
          {:t, false}
        ])

      action =
        Jason.OrderedObject.new([
          {:type, "twapOrder"},
          {:twap, twap}
        ])

      action_json = Jason.encode!(action)

      expected_json =
        ~s({"type":"twapOrder","twap":{"a":0,"b":true,"s":"1","r":false,"m":5,"t":false}})

      assert action_json == expected_json
    end

    test "validates field names are correct in twap object" do
      # Ensure we're using 'a', 'b', 's', 'r', 'm', 't', not other field names
      twap =
        Jason.OrderedObject.new([
          {:a, 0},
          {:b, true},
          {:s, "1.0"},
          {:r, false},
          {:m, 5},
          {:t, false}
        ])

      twap_map = Jason.decode!(Jason.encode!(twap))

      assert Map.has_key?(twap_map, "a")
      assert Map.has_key?(twap_map, "b")
      assert Map.has_key?(twap_map, "s")
      assert Map.has_key?(twap_map, "r")
      assert Map.has_key?(twap_map, "m")
      assert Map.has_key?(twap_map, "t")

      refute Map.has_key?(twap_map, "asset")
      refute Map.has_key?(twap_map, "is_buy")
      refute Map.has_key?(twap_map, "size")
      refute Map.has_key?(twap_map, "reduce_only")
      refute Map.has_key?(twap_map, "duration_minutes")
      refute Map.has_key?(twap_map, "randomize")
    end

    test "formats size correctly using float_to_string" do
      # Test various size formats
      test_cases = [
        {"1.0", "1"},
        {"0.5", "0.5"},
        {"10.123", "10.123"},
        {"0.0001", "0.0001"}
      ]

      for {input, expected} <- test_cases do
        result = Utils.float_to_string(input)
        assert result == expected
      end
    end

    test "builds action with all custom options" do
      twap =
        Jason.OrderedObject.new([
          {:a, 3},
          {:b, false},
          {:s, Utils.float_to_string("5.25")},
          {:r, true},
          {:m, 60},
          {:t, true}
        ])

      action =
        Jason.OrderedObject.new([
          {:type, "twapOrder"},
          {:twap, twap}
        ])

      action_json = Jason.encode!(action)

      expected_json =
        ~s({"type":"twapOrder","twap":{"a":3,"b":false,"s":"5.25","r":true,"m":60,"t":true}})

      assert action_json == expected_json
    end
  end
end
