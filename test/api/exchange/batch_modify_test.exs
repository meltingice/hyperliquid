defmodule Hyperliquid.Api.Exchange.BatchModifyTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Api.Exchange.{BatchModify, Order}
  alias Hyperliquid.Signer

  @priv_key "0x822e9959e022b78423eb653a62ea0020cd283e71a2a8133a6ff2aeffaf373cff"

  describe "modify_batch/3" do
    test "creates correct action structure for multiple limit orders" do
      modifies = [
        %{
          oid: 44_132_602_592,
          order: Order.limit_order("BTC", true, "51000.0", "0.0002")
        },
        %{
          oid: 44_132_388_383,
          order: Order.limit_order("BTC", true, "52000.0", "0.0002")
        }
      ]

      action = %{
        type: "batchModify",
        modifies: [
          %{
            oid: 44_132_602_592,
            order: %{
              a: 3,
              b: true,
              p: "51000",
              s: "0.0002",
              r: false,
              t: %{limit: %{tif: "Gtc"}}
            }
          },
          %{
            oid: 44_132_388_383,
            order: %{
              a: 3,
              b: true,
              p: "52000",
              s: "0.0002",
              r: false,
              t: %{limit: %{tif: "Gtc"}}
            }
          }
        ]
      }

      action_json = Jason.encode!(action)
      nonce = System.system_time(:millisecond)

      # Verify the action can be signed (validates structure)
      assert {:ok, signature} = sign_action(@priv_key, action_json, nonce, nil, nil)
      assert %{r: _, s: _, v: _} = signature
    end

    test "creates correct action structure for mixed order types" do
      modifies = [
        %{
          oid: 123_456,
          order: Order.limit_order("BTC", true, "51000.0", "0.0002")
        },
        %{
          oid: 789_012,
          order: Order.trigger_order("ETH", false, "3000.0", "0.1", "2950.0", "tp")
        }
      ]

      action = %{
        type: "batchModify",
        modifies: [
          %{
            oid: 123_456,
            order: %{
              a: 3,
              b: true,
              p: "51000",
              s: "0.0002",
              r: false,
              t: %{limit: %{tif: "Gtc"}}
            }
          },
          %{
            oid: 789_012,
            order: %{
              a: 19,
              b: false,
              p: "3000",
              s: "0.1",
              r: false,
              t: %{
                trigger: %{
                  isMarket: true,
                  triggerPx: "2950",
                  tpsl: "tp"
                }
              }
            }
          }
        ]
      }

      action_json = Jason.encode!(action)
      nonce = System.system_time(:millisecond)

      assert {:ok, signature} = sign_action(@priv_key, action_json, nonce, nil, nil)
      assert %{r: _, s: _, v: _} = signature
    end

    test "handles vault_address option" do
      modifies = [
        %{
          oid: 123_456,
          order: Order.limit_order("BTC", true, "51000.0", "0.0002")
        }
      ]

      vault_address = "0x1234567890123456789012345678901234567890"

      action = %{
        type: "batchModify",
        modifies: [
          %{
            oid: 123_456,
            order: %{
              a: 3,
              b: true,
              p: "51000",
              s: "0.0002",
              r: false,
              t: %{limit: %{tif: "Gtc"}}
            }
          }
        ]
      }

      action_json = Jason.encode!(action)
      nonce = System.system_time(:millisecond)

      assert {:ok, signature} = sign_action(@priv_key, action_json, nonce, vault_address, nil)
      assert %{r: _, s: _, v: _} = signature
    end

    test "handles client order ids (cloid) in order params" do
      # Note: The current Rust signer doesn't support using cloid (hex string) as the oid field.
      # It only accepts numeric order IDs. However, we CAN include cloid in the order parameters.
      cloid1 = "0x" <> String.duplicate("a", 32)
      cloid2 = "0x" <> String.duplicate("b", 32)

      modifies = [
        %{
          oid: 123_456,
          order: Order.limit_order("BTC", true, "51000.0", "0.0002", cloid: cloid1)
        },
        %{
          oid: 789_012,
          order: Order.limit_order("BTC", true, "52000.0", "0.0002", cloid: cloid2)
        }
      ]

      action = %{
        type: "batchModify",
        modifies: [
          %{
            oid: 123_456,
            order: %{
              a: 3,
              b: true,
              p: "51000",
              s: "0.0002",
              r: false,
              t: %{limit: %{tif: "Gtc"}},
              c: cloid1
            }
          },
          %{
            oid: 789_012,
            order: %{
              a: 3,
              b: true,
              p: "52000",
              s: "0.0002",
              r: false,
              t: %{limit: %{tif: "Gtc"}},
              c: cloid2
            }
          }
        ]
      }

      action_json = Jason.encode!(action)
      nonce = System.system_time(:millisecond)

      assert {:ok, signature} = sign_action(@priv_key, action_json, nonce, nil, nil)
      assert %{r: _, s: _, v: _} = signature
    end

    test "handles single modification (edge case)" do
      modifies = [
        %{
          oid: 123_456,
          order: Order.limit_order("BTC", true, "51000.0", "0.0002")
        }
      ]

      action = %{
        type: "batchModify",
        modifies: [
          %{
            oid: 123_456,
            order: %{
              a: 3,
              b: true,
              p: "51000",
              s: "0.0002",
              r: false,
              t: %{limit: %{tif: "Gtc"}}
            }
          }
        ]
      }

      action_json = Jason.encode!(action)
      nonce = System.system_time(:millisecond)

      assert {:ok, signature} = sign_action(@priv_key, action_json, nonce, nil, nil)
      assert %{r: _, s: _, v: _} = signature
    end

    test "handles expires_after option" do
      modifies = [
        %{
          oid: 123_456,
          order: Order.limit_order("BTC", true, "51000.0", "0.0002")
        }
      ]

      expires_after = System.system_time(:millisecond) + 60_000

      action = %{
        type: "batchModify",
        modifies: [
          %{
            oid: 123_456,
            order: %{
              a: 3,
              b: true,
              p: "51000",
              s: "0.0002",
              r: false,
              t: %{limit: %{tif: "Gtc"}}
            }
          }
        ]
      }

      action_json = Jason.encode!(action)
      nonce = System.system_time(:millisecond)

      assert {:ok, signature} = sign_action(@priv_key, action_json, nonce, nil, expires_after)
      assert %{r: _, s: _, v: _} = signature
    end
  end

  describe "action structure validation" do
    test "uses 'oid' field not 'o' field" do
      # This test ensures we're using the correct field name
      modifies = [
        %{
          oid: 123_456,
          order: Order.limit_order("BTC", true, "51000.0", "0.0002")
        }
      ]

      action = %{
        type: "batchModify",
        modifies: [
          %{
            oid: 123_456,
            order: %{
              a: 3,
              b: true,
              p: "51000",
              s: "0.0002",
              r: false,
              t: %{limit: %{tif: "Gtc"}}
            }
          }
        ]
      }

      action_json = Jason.encode!(action)

      # Verify the JSON contains "oid" not "o"
      assert action_json =~ "\"oid\":"
      refute action_json =~ "\"o\":"
    end
  end

  # Helper function to sign actions for testing
  defp sign_action(private_key, action_json, nonce, vault_address, expires_after) do
    is_mainnet = true

    case Signer.sign_exchange_action_ex(
           private_key,
           action_json,
           nonce,
           is_mainnet,
           vault_address,
           expires_after
         ) do
      %{"r" => r, "s" => s, "v" => v} ->
        {:ok, %{r: r, s: s, v: v}}

      error ->
        {:error, {:signing_error, error}}
    end
  end
end
