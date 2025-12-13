defmodule Hyperliquid.SignerUserSignedTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Signer

  @priv_key "0x822e9959e022b78423eb653a62ea0020cd283e71a2a8133a6ff2aeffaf373cff"

  describe "usdSend EIP-712 signature" do
    test "matches vector from TS suite (mainnet domain)" do
      destination = "0x1234567890123456789012345678901234567890"
      amount = "1000"
      time = 1_234_567_890

      sig = Signer.sign_usd_send(@priv_key, destination, amount, time, true)
      # NIF returns a map with keys "r","s","v"
      sig = Map.take(sig, ["r", "s", "v"])

      assert sig["r"] == "0xf777c38efe7c24cc71209526ae608f4e384d0586edf578f0e97b4b9f7c7adcc6"
      assert sig["s"] == "0x104a4a97c48ae77bf5bd777bdd45fe72d8f5ff29116b5ff64fd8cfe4ea610786"
      assert sig["v"] == 28
    end
  end
end
