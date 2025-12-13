defmodule Hyperliquid.SignerMultiSigTest do
  use ExUnit.Case, async: true

  alias Hyperliquid.Signer

  @priv_key "0x822e9959e022b78423eb653a62ea0020cd283e71a2a8133a6ff2aeffaf373cff"

  defp hex32(<<"0x", rest::binary>>) do
    "0x" <> String.pad_leading(rest, 64, "0")
  end

  @action_json ~S({
    "signatureChainId": "0x66eee",
    "signatures": [
      {
        "r": "0x29f311b52c9e240f515c65eded550375aa64c847a03362c6f79429b21f349b54",
        "s": "0x4838140a3d4c0887a49eac5e618aca790878572da9840ee05a70ee39effc8542",
        "v": 27
      },
      {
        "r": "0x42519dee3001e1a1306c77056e1d3c4516d7fad4d1a365a229dd5b5fb09d3491",
        "s": "0x4486a74320fbd9ef3742e5fbd8112e99eaf5e5674511ee8600911fdbf2ea0fd8",
        "v": 27
      }
    ],
    "payload": {
      "multiSigUser": "0x1234567890123456789012345678901234567890",
      "outerSigner": "0xE5cA49Fb3bD9A581F0D1EF9CB5D7177Da08bf901",
      "action": {
        "type": "scheduleCancel",
        "time": 1234567890
      }
    }
  })

  @nonce 1_234_567_890
  @vault "0x1234567890123456789012345678901234567890"
  @expires 1_234_567_890

  describe "sign multi-sig L1 action" do
    test "mainnet: without vault + expiresAfter" do
      sig =
        Signer.sign_multi_sig_action_ex(
          @priv_key,
          @action_json,
          @nonce,
          true,
          nil,
          nil
        )

      assert hex32(sig["r"]) ==
               "0x0e407746b2932cf73eedc314ccd7a24fde2a5744e276b784d4344c89c9e0c30a"

      assert hex32(sig["s"]) ==
               "0x73fb175e95590e0fc8d452b300b88951b9226026d0b6d70016b2c49c2634a905"

      assert sig["v"] == 27
    end

    test "mainnet: with vaultAddress" do
      sig =
        Signer.sign_multi_sig_action_ex(
          @priv_key,
          @action_json,
          @nonce,
          true,
          @vault,
          nil
        )

      assert hex32(sig["r"]) ==
               "0x67dc2d43c70f3aef1e47ea9fbe235e359cc7baed46776a3e131f9a7a6c5da369"

      assert hex32(sig["s"]) ==
               "0x283578ddca36e43fe832733c6a3347c491ea4b3dd9c68f25371a29b4ee862511"

      assert sig["v"] == 28
    end

    test "mainnet: with expiresAfter" do
      sig =
        Signer.sign_multi_sig_action_ex(
          @priv_key,
          @action_json,
          @nonce,
          true,
          nil,
          @expires
        )

      assert hex32(sig["r"]) ==
               "0x22024103daaf05a02f34d60ffdcf8124a7d6ddeb34f7ff6e6648e050d53efb11"

      assert hex32(sig["s"]) ==
               "0x5decc6f07bc457c77bc654f29836fea1d43c3b387cacc87537154a17c9dbacaa"

      assert sig["v"] == 28
    end

    test "mainnet: with vaultAddress + expiresAfter" do
      sig =
        Signer.sign_multi_sig_action_ex(
          @priv_key,
          @action_json,
          @nonce,
          true,
          @vault,
          @expires
        )

      assert hex32(sig["r"]) ==
               "0x65fcf5fdae7e88b006b205d0163e4b08e1759b6ce5e83851afda57faecbe2936"

      assert hex32(sig["s"]) ==
               "0x0c1507b6263279c676154f26f09882eb6d34fd3b37954d2719eecc50b2bec314"

      assert sig["v"] == 28
    end

    test "testnet: without vault + expiresAfter" do
      sig =
        Signer.sign_multi_sig_action_ex(
          @priv_key,
          @action_json,
          @nonce,
          false,
          nil,
          nil
        )

      assert hex32(sig["r"]) ==
               "0xd67004aeb75dafe40d549e7e09d7fe4a37bdaadb78125f0ab660bcdb5c35da26"

      assert hex32(sig["s"]) ==
               "0x30edb07fff6396e2e4de6c6eeb80dbd3be8aa8949e9afc2b6714c03408a68c48"

      assert sig["v"] == 28
    end

    test "testnet: with vaultAddress" do
      sig =
        Signer.sign_multi_sig_action_ex(
          @priv_key,
          @action_json,
          @nonce,
          false,
          @vault,
          nil
        )

      assert hex32(sig["r"]) ==
               "0x2aad19dbab1d2cb621a52f3b59ed402b9ee12bce4030c44619b5ee25a354df1e"

      assert hex32(sig["s"]) ==
               "0x6df0773733caf7b1a320556027c6e1645ced80a143b50aa91abdf0d63261d9b3"

      assert sig["v"] == 27
    end

    test "testnet: with expiresAfter" do
      sig =
        Signer.sign_multi_sig_action_ex(
          @priv_key,
          @action_json,
          @nonce,
          false,
          nil,
          @expires
        )

      assert hex32(sig["r"]) ==
               "0x617cb0cb69e7463f37fc121562d3553dc050e8db48c165dfa7f16f3cc85eec78"

      assert hex32(sig["s"]) ==
               "0x086b0bcd31996d3631a843cfb1af7aa73825ee04d8093f8c29a0b7b322e39657"

      assert sig["v"] == 27
    end

    test "testnet: with vaultAddress + expiresAfter" do
      sig =
        Signer.sign_multi_sig_action_ex(
          @priv_key,
          @action_json,
          @nonce,
          false,
          @vault,
          @expires
        )

      assert hex32(sig["r"]) ==
               "0x4c7ed6c2678688fb8b64ec2d734b1b89aaf276a0a2f3d72a9099d85ddf618818"

      assert hex32(sig["s"]) ==
               "0x5a28fcc6d506d7c331a936848cd5c8bbe013019d48df8a1101902996cb893fb3"

      assert sig["v"] == 27
    end
  end
end
