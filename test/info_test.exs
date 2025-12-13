defmodule Hyperliquid.Api.InfoTest do
  use ExUnit.Case, async: false

  alias Hyperliquid.Api.Info

  setup do
    bypass = Bypass.open()

    # Point both API bases at the test server (info uses http_url)
    Application.put_env(:hyperliquid, :http_url, "http://localhost:#{bypass.port}")
    Application.put_env(:hyperliquid, :rpc_url, "http://localhost:#{bypass.port}")

    {:ok, bypass: bypass}
  end

  test "all_mids posts to /info with type=allMids and returns decoded json", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/info", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["type"] == "allMids"

      resp = %{
        "status" => "ok",
        "response" => %{
          "type" => "allMids",
          "data" => %{"BTC" => "50000.0", "ETH" => "2500.0"}
        }
      }

      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(resp))
    end)

    assert {:ok, %{"status" => "ok", "response" => %{"type" => "allMids"}} = _} = Info.all_mids()
  end

  test "clearinghouse_state requires user param", _ctx do
    # The function should raise before any HTTP request is made, so no Bypass expectation here.
    assert_raise ArgumentError, ~r/required param user is nil/, fn ->
      Info.clearinghouse_state(nil)
    end
  end
end
