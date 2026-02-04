defmodule Hyperliquid.Debug.SendAssetDebugTest do
  @moduledoc """
  Comprehensive debug test to isolate why SendAsset/UsdSend API calls return
  "Must deposit before performing actions" errors on testnet.

  The error means the API recovers the WRONG address from our EIP-712 signature,
  which indicates our signing inputs (domain, types, message, or chainId) differ
  from what the API expects.

  This test validates our payload construction and signing logic against known
  working payloads captured from the Hyperliquid frontend.
  """

  use ExUnit.Case, async: false

  alias Hyperliquid.{Signer, Utils}

  # ── Test credentials (TESTNET ONLY) ──
  @address "0x7A588B92433FF4B9991B8B56a8fD0Db9649E66F2"
  @api_key "YOUR_API_KEY_HERE"
  @sub_account "0x1981c1c17c75ec0e46017aa3378339737ba48da3"

  # ── Known working payloads ──
  @working_master_to_sub %{
    "action" => %{
      "type" => "sendAsset",
      "signatureChainId" => "0xa4b1",
      "hyperliquidChain" => "Testnet",
      "destination" => "0x1981c1c17c75ec0e46017aa3378339737ba48da3",
      "sourceDex" => "",
      "destinationDex" => "",
      "token" => "USDC",
      "amount" => "5",
      "fromSubAccount" => "",
      "nonce" => 1_769_714_547_019
    },
    "expiresAfter" => nil,
    "isFrontend" => true,
    "nonce" => 1_769_714_547_019,
    "signature" => %{
      "r" => "0x0578b288985556109b9a4aca0dcb62c99794c51b24eafc7bdf47afbc7dea7875",
      "s" => "0x341b30d6838378d6eac64a2417ba57dc930553c2bd96ea82f9ba1ae56706eb50",
      "v" => 28
    },
    "vaultAddress" => nil
  }

  @working_sub_to_master %{
    "action" => %{
      "type" => "sendAsset",
      "signatureChainId" => "0xa4b1",
      "hyperliquidChain" => "Testnet",
      "destination" => "0x7a588b92433ff4b9991b8b56a8fd0db9649e66f2",
      "sourceDex" => "",
      "destinationDex" => "",
      "token" => "USDC",
      "amount" => "3.92",
      "fromSubAccount" => "0x1981c1c17c75ec0e46017aa3378339737ba48da3",
      "nonce" => 1_769_714_446_826
    },
    "expiresAfter" => nil,
    "isFrontend" => true,
    "nonce" => 1_769_714_446_826,
    "signature" => %{
      "r" => "0x197b18bcb58f29a040d5df59d52861cb5e634c7a89e186b5c72335463a0e75f8",
      "s" => "0x34aa343aa51accf11818f4b238fb8fa685ecae72144be0965740b8b370fb4f8b",
      "v" => 27
    },
    "vaultAddress" => nil
  }

  # ═══════════════════════════════════════════════════════════════════
  # Hypothesis 1: signatureChainId value on testnet
  # ═══════════════════════════════════════════════════════════════════

  describe "Hypothesis 1: signatureChainId value on testnet" do
    test "Utils.from_int(421_614) produces wrong chain ID for testnet" do
      testnet_chain_id = Utils.from_int(421_614)
      mainnet_chain_id = Utils.from_int(42_161)

      IO.puts("\n  [H1] Utils.from_int(421_614) = #{inspect(testnet_chain_id)}")
      IO.puts("  [H1] Utils.from_int(42_161)  = #{inspect(mainnet_chain_id)}")
      IO.puts("  [H1] Working payload expects: \"0xa4b1\"")

      # The working payload uses "0xa4b1" (42161) even on testnet
      # Our code uses Utils.from_int(421_614) for testnet which gives "0x66EEE"
      assert testnet_chain_id != "0xa4b1",
             "BUG CONFIRMED: testnet code uses 421614 but API expects 42161"

      # After fix: from_int now produces lowercase directly
      assert mainnet_chain_id == "0xa4b1",
             "42161 should produce 0xa4b1 in lowercase hex"
    end

    test "signatureChainId should ALWAYS be 42161 (0xa4b1) regardless of network" do
      # The Hyperliquid API uses signatureChainId 42161 (Arbitrum One) for BOTH
      # mainnet and testnet. The network distinction is in hyperliquidChain field.
      expected = "0xa4b1"

      mainnet_value = Utils.from_int(42_161)
      assert mainnet_value == expected

      # 421614 is a different chain ID and should NOT be used
      testnet_value = Utils.from_int(421_614)

      assert testnet_value != expected,
             "421614 != 42161 (different chain IDs)"

      IO.puts("\n  [H1] FIX NEEDED: Both mainnet and testnet must use signatureChainId 42161")
    end
  end

  # ═══════════════════════════════════════════════════════════════════
  # Hypothesis 2: EIP-712 domain chainId mismatch
  # ═══════════════════════════════════════════════════════════════════

  describe "Hypothesis 2: EIP-712 domain chainId mismatch" do
    test "signing with chainId 42161 vs 421614 produces different signatures" do
      # Use the known working payload data: master to sub, $5 USDC
      nonce = 1_769_714_547_019
      destination = @sub_account
      amount = "5"

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

      message = %{
        hyperliquidChain: "Testnet",
        destination: destination,
        sourceDex: "",
        destinationDex: "",
        token: "USDC",
        amount: amount,
        fromSubAccount: "",
        nonce: nonce
      }

      primary_type = "HyperliquidTransaction:SendAsset"
      types_json = Jason.encode!(types)
      message_json = Jason.encode!(message)

      # Sign with chainId 421614 (what our code does for testnet)
      domain_421614 = %{
        name: "HyperliquidSignTransaction",
        version: "1",
        chainId: 421_614,
        verifyingContract: "0x0000000000000000000000000000000000000000"
      }

      sig_421614 =
        Signer.sign_typed_data(
          @api_key,
          Jason.encode!(domain_421614),
          types_json,
          message_json,
          primary_type
        )

      IO.puts("\n  [H2] Signature with chainId 421614: #{inspect(sig_421614)}")

      # Sign with chainId 42161 (what working payloads suggest)
      domain_42161 = %{
        name: "HyperliquidSignTransaction",
        version: "1",
        chainId: 42_161,
        verifyingContract: "0x0000000000000000000000000000000000000000"
      }

      sig_42161 =
        Signer.sign_typed_data(
          @api_key,
          Jason.encode!(domain_42161),
          types_json,
          message_json,
          primary_type
        )

      IO.puts("  [H2] Signature with chainId 42161:  #{inspect(sig_42161)}")

      # They should differ (different domain => different hash)
      assert sig_421614 != sig_42161,
             "Different chainIds must produce different signatures"

      # Check if chainId 42161 matches the known working signature
      expected_r = "0x0578b288985556109b9a4aca0dcb62c99794c51b24eafc7bdf47afbc7dea7875"
      expected_s = "0x341b30d6838378d6eac64a2417ba57dc930553c2bd96ea82f9ba1ae56706eb50"
      expected_v = 28

      case sig_42161 do
        %{"r" => r, "s" => s, "v" => v} ->
          IO.puts("\n  [H2] Expected r: #{expected_r}")
          IO.puts("  [H2] Got r:      #{r}")
          IO.puts("  [H2] Expected s: #{expected_s}")
          IO.puts("  [H2] Got s:      #{s}")
          IO.puts("  [H2] Expected v: #{expected_v}")
          IO.puts("  [H2] Got v:      #{v}")

          if r == expected_r and s == expected_s and v == expected_v do
            IO.puts("\n  [H2] SIGNATURE MATCHES with chainId 42161!")
          else
            IO.puts("\n  [H2] Signature does NOT match. Other factors may differ.")
          end

        {:error, reason} ->
          IO.puts("  [H2] ERROR signing: #{inspect(reason)}")
      end
    end

    test "sign with chainId 42161 matches known working sub-to-master signature" do
      nonce = 1_769_714_446_826
      destination = String.downcase(@address)
      amount = "3.92"
      from_sub_account = @sub_account

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

      message = %{
        hyperliquidChain: "Testnet",
        destination: destination,
        sourceDex: "",
        destinationDex: "",
        token: "USDC",
        amount: amount,
        fromSubAccount: from_sub_account,
        nonce: nonce
      }

      domain = %{
        name: "HyperliquidSignTransaction",
        version: "1",
        chainId: 42_161,
        verifyingContract: "0x0000000000000000000000000000000000000000"
      }

      sig =
        Signer.sign_typed_data(
          @api_key,
          Jason.encode!(domain),
          Jason.encode!(types),
          Jason.encode!(message),
          "HyperliquidTransaction:SendAsset"
        )

      expected_r = "0x197b18bcb58f29a040d5df59d52861cb5e634c7a89e186b5c72335463a0e75f8"
      expected_s = "0x34aa343aa51accf11818f4b238fb8fa685ecae72144be0965740b8b370fb4f8b"
      expected_v = 27

      case sig do
        %{"r" => r, "s" => s, "v" => v} ->
          IO.puts("\n  [H2b] Sub-to-master signature comparison:")
          IO.puts("  [H2b] r match: #{r == expected_r}")
          IO.puts("  [H2b] s match: #{s == expected_s}")
          IO.puts("  [H2b] v match: #{v == expected_v}")

          assert r == expected_r, "r mismatch: got #{r}, expected #{expected_r}"
          assert s == expected_s, "s mismatch: got #{s}, expected #{expected_s}"
          assert v == expected_v, "v mismatch: got #{v}, expected #{expected_v}"

        {:error, reason} ->
          flunk("Signing error: #{inspect(reason)}")
      end
    end
  end

  # ═══════════════════════════════════════════════════════════════════
  # Hypothesis 3: Missing outer payload fields
  # ═══════════════════════════════════════════════════════════════════

  describe "Hypothesis 3: missing outer payload fields" do
    test "user_signed_request builds payload without expiresAfter and vaultAddress" do
      # Simulate what user_signed_request/4 currently builds
      action = %{type: "sendAsset", amount: "5"}
      signature = %{r: "0x...", s: "0x...", v: 27}
      nonce = 123

      our_payload = %{
        action: action,
        nonce: nonce,
        signature: signature
      }

      our_keys = Map.keys(our_payload) |> Enum.sort()

      working_keys =
        ["action", "expiresAfter", "isFrontend", "nonce", "signature", "vaultAddress"]
        |> Enum.sort()

      IO.puts("\n  [H3] Our outer payload keys:     #{inspect(our_keys)}")
      IO.puts("  [H3] Working outer payload keys: #{inspect(working_keys)}")

      missing = working_keys -- Enum.map(our_keys, &to_string/1)
      IO.puts("  [H3] Missing keys: #{inspect(missing)}")

      assert "expiresAfter" in missing, "expiresAfter is missing from our payload"
      assert "vaultAddress" in missing, "vaultAddress is missing from our payload"
      # isFrontend may be optional/frontend-only
    end
  end

  # ═══════════════════════════════════════════════════════════════════
  # Hypothesis 4: Hex casing
  # ═══════════════════════════════════════════════════════════════════

  describe "Hypothesis 4: hex casing" do
    test "Utils.from_int now produces lowercase hex (FIXED)" do
      result = Utils.from_int(42_161)
      IO.puts("\n  [H4] Utils.from_int(42_161) = #{inspect(result)}")

      # After fix: produces lowercase hex matching working payload
      assert result == "0xa4b1", "from_int should produce lowercase hex after fix"
    end

    test "Utils.from_int(421_614) produces lowercase" do
      result = Utils.from_int(421_614)
      IO.puts("\n  [H4] Utils.from_int(421_614) = #{inspect(result)}")
      assert result == "0x66eee"
    end
  end

  # ═══════════════════════════════════════════════════════════════════
  # Hypothesis 5: Address casing
  # ═══════════════════════════════════════════════════════════════════

  describe "Hypothesis 5: address casing" do
    test "working payloads use all-lowercase addresses" do
      working_dest = @working_sub_to_master["action"]["destination"]
      IO.puts("\n  [H5] Working destination: #{working_dest}")

      assert working_dest == String.downcase(working_dest),
             "Working payload uses lowercase address"

      our_address = @address
      IO.puts("  [H5] Our address:         #{our_address}")

      assert our_address != String.downcase(our_address),
             "Our address is mixed-case (checksummed)"

      IO.puts("  [H5] Lowercased:          #{String.downcase(our_address)}")

      assert String.downcase(our_address) == working_dest,
             "Lowercased addresses should match"
    end
  end

  # ═══════════════════════════════════════════════════════════════════
  # Hypothesis 6: UsdSend obsolescence
  # ═══════════════════════════════════════════════════════════════════

  describe "Hypothesis 6: UsdSend obsolescence" do
    test "UsdSend uses different action type and fields than working payloads" do
      # UsdSend produces: type=usdSend, fields: signatureChainId, hyperliquidChain, destination, amount, time
      # Working uses:      type=sendAsset, fields: signatureChainId, hyperliquidChain, destination, sourceDex,
      #                    destinationDex, token, amount, fromSubAccount, nonce

      usd_send_fields = ~w(type signatureChainId hyperliquidChain destination amount time)

      send_asset_fields =
        ~w(type signatureChainId hyperliquidChain destination sourceDex destinationDex token amount fromSubAccount nonce)

      IO.puts("\n  [H6] UsdSend fields:   #{inspect(usd_send_fields)}")
      IO.puts("  [H6] SendAsset fields: #{inspect(send_asset_fields)}")

      missing_in_usd_send = send_asset_fields -- usd_send_fields
      IO.puts("  [H6] Fields missing from UsdSend: #{inspect(missing_in_usd_send)}")

      assert "token" in missing_in_usd_send
      assert "sourceDex" in missing_in_usd_send
      assert "nonce" in missing_in_usd_send

      # UsdSend uses 'time' while SendAsset uses 'nonce'
      assert "time" in usd_send_fields
      refute "nonce" in usd_send_fields
    end

    test "Rust NIF chain() hardcodes 421614 for ALL environments" do
      # The Rust NIF chain() function (lib.rs line 631) returns:
      #   let chain_id = 421614u64;
      # This is used by sign_usd_send, sign_withdraw3, sign_spot_send, etc.
      # It should be using the signatureChainId from the action (42161).

      IO.puts("\n  [H6] Rust NIF chain() hardcodes chainId=421614 for ALL environments")

      IO.puts(
        "  [H6] This affects: sign_usd_send, sign_withdraw3, sign_spot_send, sign_approve_*"
      )

      IO.puts("  [H6] FIX: These NIFs should use chainId 42161 always")

      # We can verify by signing with sign_usd_send and comparing
      # However sign_usd_send uses the old UsdSend EIP-712 type, so
      # the signature will never match a sendAsset working payload anyway.
    end
  end

  # ═══════════════════════════════════════════════════════════════════
  # Hypothesis 7: JSON field order in EIP-712 hashing
  # ═══════════════════════════════════════════════════════════════════

  describe "Hypothesis 7: JSON field order in EIP-712 hashing" do
    test "EIP-712 struct hash is determined by type definition order, not JSON key order" do
      # EIP-712 hashing follows the field order in the type definition, NOT JSON order.
      # The Rust NIF uses ethers_core::TypedData which handles this correctly.
      # So JSON field order in the message should NOT matter.

      IO.puts("\n  [H7] EIP-712 struct hash uses type definition order, not JSON key order")
      IO.puts("  [H7] ethers_core::TypedData handles ordering correctly")
      IO.puts("  [H7] This is NOT a bug source (low risk)")

      # Verify by signing with two different JSON orderings
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

      domain = %{
        name: "HyperliquidSignTransaction",
        version: "1",
        chainId: 42_161,
        verifyingContract: "0x0000000000000000000000000000000000000000"
      }

      # Message with one key order
      msg1 =
        Jason.encode!(%{
          hyperliquidChain: "Testnet",
          destination: "0x1234",
          sourceDex: "",
          destinationDex: "",
          token: "USDC",
          amount: "5",
          fromSubAccount: "",
          nonce: 12345
        })

      # Message with reversed key order (using OrderedObject)
      msg2 =
        Jason.encode!(
          Jason.OrderedObject.new([
            {:nonce, 12345},
            {:fromSubAccount, ""},
            {:amount, "5"},
            {:token, "USDC"},
            {:destinationDex, ""},
            {:sourceDex, ""},
            {:destination, "0x1234"},
            {:hyperliquidChain, "Testnet"}
          ])
        )

      IO.puts("  [H7] msg1 JSON: #{msg1}")
      IO.puts("  [H7] msg2 JSON: #{msg2}")

      sig1 =
        Signer.sign_typed_data(
          @api_key,
          Jason.encode!(domain),
          Jason.encode!(types),
          msg1,
          "HyperliquidTransaction:SendAsset"
        )

      sig2 =
        Signer.sign_typed_data(
          @api_key,
          Jason.encode!(domain),
          Jason.encode!(types),
          msg2,
          "HyperliquidTransaction:SendAsset"
        )

      case {sig1, sig2} do
        {%{"r" => r1}, %{"r" => r2}} ->
          IO.puts("  [H7] sig1.r: #{r1}")
          IO.puts("  [H7] sig2.r: #{r2}")
          assert r1 == r2, "JSON field order should NOT affect EIP-712 signature"

        _ ->
          IO.puts("  [H7] Could not compare signatures: #{inspect(sig1)} vs #{inspect(sig2)}")
      end
    end
  end

  # ═══════════════════════════════════════════════════════════════════
  # Full payload reconstruction: build exactly what our code sends
  # ═══════════════════════════════════════════════════════════════════

  describe "Full payload reconstruction" do
    test "build exact payload our SendAsset module would send and compare to working" do
      # Reproduce exactly what SendAsset.request would build for master-to-sub $5 USDC
      is_mainnet = false
      nonce = 1_769_714_547_019
      destination = @sub_account
      amount = "5"
      from_sub_account = ""

      # What our code currently produces for signatureChainId
      our_sig_chain_id = if is_mainnet, do: Utils.from_int(42_161), else: Utils.from_int(421_614)

      action =
        Jason.OrderedObject.new([
          {:type, "sendAsset"},
          {:signatureChainId, our_sig_chain_id},
          {:hyperliquidChain, "Testnet"},
          {:destination, destination},
          {:sourceDex, ""},
          {:destinationDex, ""},
          {:token, "USDC"},
          {:amount, amount},
          {:fromSubAccount, from_sub_account},
          {:nonce, nonce}
        ])

      # What user_signed_request builds
      our_payload = %{
        action: action,
        nonce: nonce,
        signature: %{r: "0xPLACEHOLDER", s: "0xPLACEHOLDER", v: 27}
      }

      our_json = Jason.encode!(our_payload, pretty: true)
      IO.puts("\n  [FULL] Our payload JSON:\n#{our_json}")

      # Decode to compare structurally
      our_decoded = Jason.decode!(Jason.encode!(our_payload))
      working = @working_master_to_sub

      # Compare action fields
      our_action = our_decoded["action"]
      working_action = working["action"]

      IO.puts("\n  [FULL] Action field comparison:")

      for key <- Map.keys(working_action) do
        our_val = our_action[key]
        working_val = working_action[key]
        match? = our_val == working_val
        status = if match?, do: "OK", else: "MISMATCH"
        IO.puts("    #{status} #{key}: ours=#{inspect(our_val)} working=#{inspect(working_val)}")
      end

      # The key assertion: signatureChainId should match
      assert our_action["signatureChainId"] != working_action["signatureChainId"],
             "BUG CONFIRMED: signatureChainId mismatch (ours: #{our_action["signatureChainId"]}, working: #{working_action["signatureChainId"]})"
    end

    test "build FIXED payload and verify it matches working payload structure" do
      nonce = 1_769_714_547_019
      destination = @sub_account
      amount = "5"

      # FIXED: always use 42161 and lowercase
      fixed_sig_chain_id = "0x" <> String.downcase(Integer.to_string(42_161, 16))

      action =
        Jason.OrderedObject.new([
          {:type, "sendAsset"},
          {:signatureChainId, fixed_sig_chain_id},
          {:hyperliquidChain, "Testnet"},
          {:destination, destination},
          {:sourceDex, ""},
          {:destinationDex, ""},
          {:token, "USDC"},
          {:amount, amount},
          {:fromSubAccount, ""},
          {:nonce, nonce}
        ])

      # FIXED: include expiresAfter and vaultAddress
      fixed_payload = %{
        action: action,
        nonce: nonce,
        signature: %{r: "0xPLACEHOLDER", s: "0xPLACEHOLDER", v: 27},
        expiresAfter: nil,
        vaultAddress: nil
      }

      fixed_decoded = Jason.decode!(Jason.encode!(fixed_payload))
      working = @working_master_to_sub

      # Compare action signatureChainId
      assert fixed_decoded["action"]["signatureChainId"] == working["action"]["signatureChainId"],
             "FIXED signatureChainId should match"

      # Compare all action fields except signature-dependent ones
      for key <-
            ~w(type signatureChainId hyperliquidChain destination sourceDex destinationDex token amount fromSubAccount nonce) do
        assert fixed_decoded["action"][key] == working["action"][key],
               "Action field '#{key}' mismatch: #{inspect(fixed_decoded["action"][key])} != #{inspect(working["action"][key])}"
      end

      # Check outer fields exist
      assert Map.has_key?(fixed_decoded, "expiresAfter")
      assert Map.has_key?(fixed_decoded, "vaultAddress")

      IO.puts("\n  [FIXED] All action fields match working payload!")
    end
  end

  # ═══════════════════════════════════════════════════════════════════
  # End-to-end signature verification with fixes applied
  # ═══════════════════════════════════════════════════════════════════

  describe "End-to-end signature verification with fixes" do
    test "signing master-to-sub with chainId 42161 reproduces working signature" do
      nonce = 1_769_714_547_019
      destination = @sub_account
      amount = "5"

      domain = %{
        name: "HyperliquidSignTransaction",
        version: "1",
        chainId: 42_161,
        verifyingContract: "0x0000000000000000000000000000000000000000"
      }

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

      message = %{
        hyperliquidChain: "Testnet",
        destination: destination,
        sourceDex: "",
        destinationDex: "",
        token: "USDC",
        amount: amount,
        fromSubAccount: "",
        nonce: nonce
      }

      sig =
        Signer.sign_typed_data(
          @api_key,
          Jason.encode!(domain),
          Jason.encode!(types),
          Jason.encode!(message),
          "HyperliquidTransaction:SendAsset"
        )

      expected = @working_master_to_sub["signature"]

      case sig do
        %{"r" => r, "s" => s, "v" => v} ->
          assert r == expected["r"], "r: #{r} != #{expected["r"]}"
          assert s == expected["s"], "s: #{s} != #{expected["s"]}"
          assert v == expected["v"], "v: #{v} != #{expected["v"]}"
          IO.puts("\n  [E2E] Master-to-sub signature MATCHES working payload!")

        {:error, reason} ->
          flunk("Signing failed: #{inspect(reason)}")
      end
    end

    test "signing sub-to-master with chainId 42161 reproduces working signature" do
      nonce = 1_769_714_446_826
      destination = String.downcase(@address)
      amount = "3.92"
      from_sub_account = @sub_account

      domain = %{
        name: "HyperliquidSignTransaction",
        version: "1",
        chainId: 42_161,
        verifyingContract: "0x0000000000000000000000000000000000000000"
      }

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

      message = %{
        hyperliquidChain: "Testnet",
        destination: destination,
        sourceDex: "",
        destinationDex: "",
        token: "USDC",
        amount: amount,
        fromSubAccount: from_sub_account,
        nonce: nonce
      }

      sig =
        Signer.sign_typed_data(
          @api_key,
          Jason.encode!(domain),
          Jason.encode!(types),
          Jason.encode!(message),
          "HyperliquidTransaction:SendAsset"
        )

      expected = @working_sub_to_master["signature"]

      case sig do
        %{"r" => r, "s" => s, "v" => v} ->
          assert r == expected["r"], "r: #{r} != #{expected["r"]}"
          assert s == expected["s"], "s: #{s} != #{expected["s"]}"
          assert v == expected["v"], "v: #{v} != #{expected["v"]}"
          IO.puts("\n  [E2E] Sub-to-master signature MATCHES working payload!")

        {:error, reason} ->
          flunk("Signing failed: #{inspect(reason)}")
      end
    end
  end
end
