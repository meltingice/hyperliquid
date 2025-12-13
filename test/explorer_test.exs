defmodule Hyperliquid.Api.ExplorerTest do
  use ExUnit.Case, async: false

  alias Hyperliquid.Api.Explorer

  setup do
    bypass = Bypass.open()

    # Explorer uses rpc_url base (context "explorer")
    Application.put_env(:hyperliquid, :rpc_url, "http://localhost:#{bypass.port}")

    {:ok, bypass: bypass}
  end

  test "block_details posts to /explorer with type=blockDetails and height", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/explorer", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["type"] == "blockDetails"
      assert payload["height"] == 12345

      resp = %{
        "status" => "ok",
        "response" => %{"type" => "blockDetails", "blockDetails" => %{"height" => 12345}}
      }

      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(resp))
    end)

    assert {:ok, %{"status" => "ok"}} = Explorer.block_details(12345)
  end

  test "tx_details requires hash param", _ctx do
    assert_raise ArgumentError, ~r/required param hash is nil/, fn ->
      Explorer.tx_details(nil)
    end
  end
end
