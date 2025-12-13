defmodule Hyperliquid.Api.StatsTest do
  use ExUnit.Case, async: false

  alias Hyperliquid.Api.Stats.{Leaderboard, Vaults}

  setup do
    bypass = Bypass.open()

    # Stats uses stats_url base
    Application.put_env(:hyperliquid, :stats_url, "http://localhost:#{bypass.port}")
    # Ensure we're using mainnet for consistent test paths
    Application.put_env(:hyperliquid, :chain, :mainnet)

    on_exit(fn ->
      Application.delete_env(:hyperliquid, :stats_url)
      Application.delete_env(:hyperliquid, :chain)
    end)

    {:ok, bypass: bypass}
  end

  describe "Leaderboard" do
    test "fetches leaderboard data from /Mainnet/leaderboard", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/Mainnet/leaderboard", fn conn ->
        resp = %{
          "leaderboardRows" => [
            %{
              "ethAddress" => "0x87f9cd15f5050a9283b8896300f7c8cf69ece2cf",
              "accountValue" => "73332516.2879340053",
              "windowPerformances" => [
                [
                  "day",
                  %{
                    "pnl" => "-637573.173681",
                    "roi" => "-0.0086193144",
                    "vlm" => "2190183478.490000248"
                  }
                ],
                [
                  "week",
                  %{
                    "pnl" => "5908161.6248070002",
                    "roi" => "0.0693468991",
                    "vlm" => "16870027909.7899971008"
                  }
                ]
              ],
              "prize" => 0,
              "displayName" => nil
            }
          ]
        }

        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(resp))
      end)

      assert {:ok, %Leaderboard{leaderboard_rows: rows}} = Leaderboard.request()
      assert is_list(rows)
      assert length(rows) == 1

      [row] = rows
      assert row["eth_address"] == "0x87f9cd15f5050a9283b8896300f7c8cf69ece2cf"
      assert row["account_value"] == "73332516.2879340053"
    end

    test "trader_count returns correct count", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/Mainnet/leaderboard", fn conn ->
        resp = %{
          "leaderboardRows" => [
            %{
              "ethAddress" => "0x123",
              "accountValue" => "1000",
              "windowPerformances" => [],
              "prize" => 0,
              "displayName" => nil
            },
            %{
              "ethAddress" => "0x456",
              "accountValue" => "2000",
              "windowPerformances" => [],
              "prize" => 0,
              "displayName" => nil
            }
          ]
        }

        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(resp))
      end)

      {:ok, leaderboard} = Leaderboard.request()
      assert Leaderboard.trader_count(leaderboard) == 2
    end

    test "get_trader finds trader by address", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/Mainnet/leaderboard", fn conn ->
        resp = %{
          "leaderboardRows" => [
            %{
              "ethAddress" => "0x123abc",
              "accountValue" => "1000",
              "windowPerformances" => [],
              "prize" => 0,
              "displayName" => "TestTrader"
            }
          ]
        }

        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(resp))
      end)

      {:ok, leaderboard} = Leaderboard.request()
      assert {:ok, trader} = Leaderboard.get_trader(leaderboard, "0x123ABC")
      assert trader["display_name"] == "TestTrader"
    end

    test "top_traders returns top N traders", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/Mainnet/leaderboard", fn conn ->
        resp = %{
          "leaderboardRows" =>
            Enum.map(1..5, fn i ->
              %{
                "ethAddress" => "0x#{i}",
                "accountValue" => "#{i * 1000}",
                "windowPerformances" => [],
                "prize" => 0,
                "displayName" => nil
              }
            end)
        }

        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(resp))
      end)

      {:ok, leaderboard} = Leaderboard.request()
      top_3 = Leaderboard.top_traders(leaderboard, 3)
      assert length(top_3) == 3
    end
  end

  describe "Vaults" do
    test "fetches vaults data from /Mainnet/vaults", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/Mainnet/vaults", fn conn ->
        resp = [
          %{
            "apr" => 0.15,
            "pnls" => [
              ["day", ["100.0", "200.0"]],
              ["week", ["500.0", "600.0"]]
            ],
            "summary" => %{
              "name" => "Test Vault",
              "vaultAddress" => "0xabc123",
              "leader" => "0xleader",
              "tvl" => "1000000.0",
              "isClosed" => false,
              "relationship" => %{"type" => "normal"},
              "createTimeMillis" => 1_736_422_051_357
            }
          }
        ]

        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(resp))
      end)

      assert {:ok, %Vaults{vaults: vaults}} = Vaults.request()
      assert is_list(vaults)
      assert length(vaults) == 1

      [vault] = vaults
      assert vault["apr"] == 0.15

      summary = vault["summary"]
      assert summary["name"] == "Test Vault"
      assert summary["vault_address"] == "0xabc123"
    end

    test "vault_count returns correct count", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/Mainnet/vaults", fn conn ->
        resp =
          Enum.map(1..3, fn i ->
            %{
              "apr" => 0.1,
              "pnls" => [],
              "summary" => %{
                "name" => "Vault #{i}",
                "vaultAddress" => "0x#{i}",
                "leader" => "0xleader",
                "tvl" => "1000.0",
                "isClosed" => false,
                "relationship" => %{"type" => "normal"},
                "createTimeMillis" => 1_736_422_051_357
              }
            }
          end)

        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(resp))
      end)

      {:ok, vaults} = Vaults.request()
      assert Vaults.vault_count(vaults) == 3
    end

    test "get_vault finds vault by address", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/Mainnet/vaults", fn conn ->
        resp = [
          %{
            "apr" => 0.2,
            "pnls" => [],
            "summary" => %{
              "name" => "My Vault",
              "vaultAddress" => "0xfindme",
              "leader" => "0xleader",
              "tvl" => "5000.0",
              "isClosed" => false,
              "relationship" => %{"type" => "normal"},
              "createTimeMillis" => 1_736_422_051_357
            }
          }
        ]

        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(resp))
      end)

      {:ok, vaults} = Vaults.request()
      assert {:ok, vault} = Vaults.get_vault(vaults, "0xFINDME")

      summary = vault["summary"]
      assert summary["name"] == "My Vault"
    end

    test "by_apr sorts vaults by APR descending", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/Mainnet/vaults", fn conn ->
        resp = [
          %{
            "apr" => 0.1,
            "pnls" => [],
            "summary" => %{
              "name" => "Low APR",
              "vaultAddress" => "0x1",
              "leader" => "0xleader",
              "tvl" => "1000.0",
              "isClosed" => false,
              "relationship" => %{"type" => "normal"},
              "createTimeMillis" => 1_736_422_051_357
            }
          },
          %{
            "apr" => 0.5,
            "pnls" => [],
            "summary" => %{
              "name" => "High APR",
              "vaultAddress" => "0x2",
              "leader" => "0xleader",
              "tvl" => "1000.0",
              "isClosed" => false,
              "relationship" => %{"type" => "normal"},
              "createTimeMillis" => 1_736_422_051_357
            }
          }
        ]

        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(resp))
      end)

      {:ok, vaults} = Vaults.request()
      sorted = Vaults.by_apr(vaults)
      [first | _] = sorted

      summary = first["summary"]
      assert summary["name"] == "High APR"
    end

    test "filter_by_status filters open/closed vaults", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/Mainnet/vaults", fn conn ->
        resp = [
          %{
            "apr" => 0.1,
            "pnls" => [],
            "summary" => %{
              "name" => "Open Vault",
              "vaultAddress" => "0x1",
              "leader" => "0xleader",
              "tvl" => "1000.0",
              "isClosed" => false,
              "relationship" => %{"type" => "normal"},
              "createTimeMillis" => 1_736_422_051_357
            }
          },
          %{
            "apr" => 0.2,
            "pnls" => [],
            "summary" => %{
              "name" => "Closed Vault",
              "vaultAddress" => "0x2",
              "leader" => "0xleader",
              "tvl" => "1000.0",
              "isClosed" => true,
              "relationship" => %{"type" => "normal"},
              "createTimeMillis" => 1_736_422_051_357
            }
          }
        ]

        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, Jason.encode!(resp))
      end)

      {:ok, vaults} = Vaults.request()
      open_vaults = Vaults.filter_by_status(vaults, false)
      closed_vaults = Vaults.filter_by_status(vaults, true)

      assert length(open_vaults) == 1
      assert length(closed_vaults) == 1
    end
  end
end
