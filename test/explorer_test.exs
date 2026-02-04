defmodule Hyperliquid.Api.ExplorerTest do
  use ExUnit.Case, async: false

  alias Hyperliquid.Api.Explorer

  setup do
    bypass = Bypass.open()

    # Explorer uses explorer_url config key
    Application.put_env(:hyperliquid, :explorer_url, "http://localhost:#{bypass.port}/explorer")

    # Stub /info to absorb cache warmer background requests
    Bypass.stub(bypass, "POST", "/info", fn conn ->
      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{}))
    end)

    {:ok, bypass: bypass}
  end

  test "block_details posts to /explorer with type=blockDetails and height", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/explorer", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["type"] == "blockDetails"
      assert payload["height"] == 12345

      resp = %{
        "blockDetails" => %{
          "height" => 12345,
          "hash" => "0xabc123",
          "blockTime" => 1_234_567_890,
          "txs" => []
        }
      }

      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(resp))
    end)

    assert {:ok, %Hyperliquid.Api.Explorer.BlockDetails{block_number: 12345}} =
             Explorer.block_details(12345)
  end

  test "tx_details with nil hash returns changeset error", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/explorer", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["type"] == "txDetails"

      # Return empty response - changeset validation will fail on missing hash
      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{}))
    end)

    assert {:error, %Ecto.Changeset{valid?: false}} = Explorer.tx_details(nil)
  end
end
