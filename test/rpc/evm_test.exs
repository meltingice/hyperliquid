defmodule Hyperliquid.Rpc.EvmTest do
  use ExUnit.Case, async: false

  alias Hyperliquid.Rpc.Evm

  setup do
    bypass = Bypass.open()
    Application.put_env(:hyperliquid, :rpc_url, "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass}
  end

  test "eth_blockNumber returns hex, decodes when requested", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/evm", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      req = Jason.decode!(body)
      assert req["method"] == "eth_blockNumber"

      resp = %{jsonrpc: "2.0", id: req["id"], result: "0x13d7e8"}

      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(resp))
    end)

    assert {:ok, "0x13d7e8"} = Evm.eth_blockNumber()

    # decode option
    Bypass.expect_once(bypass, "POST", "/evm", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      req = Jason.decode!(body)
      assert req["method"] == "eth_blockNumber"

      resp = %{jsonrpc: "2.0", id: req["id"], result: "0x13d7e8"}

      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(resp))
    end)

    assert {:ok, 1_300_456} = Evm.eth_blockNumber(decode: true)
  end

  test "eth_call enforces latest-only", _ctx do
    assert_raise ArgumentError, ~r/eth_call supports only latest block/, fn ->
      Evm.eth_call(%{to: "0xdeadbeef"}, "0x1")
    end
  end

  test "eth_getLogs validates topics and range", %{bypass: bypass} do
    # topics > 4
    assert_raise ArgumentError, ~r/4 topics/, fn ->
      Evm.eth_getLogs(%{address: "0x0", topics: [1, 2, 3, 4, 5]})
    end

    # > 50 blocks
    assert_raise ArgumentError, ~r/50 blocks/, fn ->
      Evm.eth_getLogs(%{fromBlock: 1, toBlock: 55})
    end

    # happy path
    Bypass.expect_once(bypass, "POST", "/evm", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      req = Jason.decode!(body)
      assert req["method"] == "eth_getLogs"

      resp = %{
        jsonrpc: "2.0",
        id: req["id"],
        result: [
          %{blockNumber: "0x10", transactionIndex: "0x1", logIndex: "0x2"}
        ]
      }

      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(resp))
    end)

    assert {:ok, [%{"blockNumber" => "0x10"}]} = Evm.eth_getLogs(%{fromBlock: 1, toBlock: 10})

    Bypass.expect_once(bypass, "POST", "/evm", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      req = Jason.decode!(body)
      assert req["method"] == "eth_getLogs"

      resp = %{
        jsonrpc: "2.0",
        id: req["id"],
        result: [
          %{blockNumber: "0x10", transactionIndex: "0x1", logIndex: "0x2"}
        ]
      }

      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(resp))
    end)

    assert {:ok, [%{"blockNumber" => 16, "transactionIndex" => 1, "logIndex" => 2}]} =
             Evm.eth_getLogs(%{fromBlock: 1, toBlock: 10}, decode: true)
  end

  test "custom method eth_bigBlockGasPrice supports decode", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/evm", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      req = Jason.decode!(body)
      assert req["method"] == "eth_bigBlockGasPrice"

      resp = %{jsonrpc: "2.0", id: req["id"], result: "0x77359400"}

      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(resp))
    end)

    assert {:ok, 2_000_000_000} = Evm.eth_bigBlockGasPrice(decode: true)
  end
end
