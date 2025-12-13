defmodule Hyperliquid.Api.MultiTableDslTest do
  # NOTE: async: false because these tests check function_exported? which can
  # have race conditions with module compilation in async mode
  use ExUnit.Case, async: false

  alias Hyperliquid.Api.Info.SpotMeta
  alias Hyperliquid.Api.Info.AllPerpMetas
  alias Hyperliquid.Api.Info.UserFills

  # Ensure modules are fully loaded before tests run
  setup_all do
    Code.ensure_loaded!(SpotMeta)
    Code.ensure_loaded!(AllPerpMetas)
    Code.ensure_loaded!(UserFills)
    :ok
  end

  # Test structs for transformation testing
  defmodule TestStruct do
    defstruct [:address, :evm_extra_wei_decimals]
  end

  defmodule TierStruct do
    defstruct [:lower_bound, :max_leverage]
  end

  describe "single-table endpoint DSL (backwards compatibility)" do
    test "UserFills has __postgres_tables__/0 function" do
      assert function_exported?(UserFills, :__postgres_tables__, 0)
    end

    test "UserFills __postgres_tables__/0 returns list with one table config" do
      tables = UserFills.__postgres_tables__()

      assert is_list(tables)
      assert length(tables) == 1
    end

    test "UserFills table config has correct structure" do
      [table_config] = UserFills.__postgres_tables__()

      assert table_config.table == "fills"
      assert table_config.extract == :fills
      assert is_nil(table_config.transform)
    end

    test "UserFills generates backwards-compatible postgres_table/0 function" do
      assert function_exported?(UserFills, :postgres_table, 0)
      assert UserFills.postgres_table() == "fills"
    end

    test "UserFills generates postgres_enabled?/0 function" do
      assert function_exported?(UserFills, :postgres_enabled?, 0)
      assert UserFills.postgres_enabled?() == true
    end
  end

  describe "multi-table endpoint DSL - SpotMeta" do
    test "has __postgres_tables__/0 function" do
      assert function_exported?(SpotMeta, :__postgres_tables__, 0)
    end

    test "__postgres_tables__/0 returns list with two table configs" do
      tables = SpotMeta.__postgres_tables__()

      assert is_list(tables)
      assert length(tables) == 2
    end

    test "first table config is correct (spot_pairs)" do
      tables = SpotMeta.__postgres_tables__()
      spot_pairs = Enum.find(tables, &(&1.table == "spot_pairs"))

      assert spot_pairs.table == "spot_pairs"
      assert spot_pairs.extract == :universe
      assert spot_pairs.conflict_target == :index
      assert {:replace, _fields} = spot_pairs.on_conflict
      assert is_nil(spot_pairs.transform)
    end

    test "second table config is correct (tokens with transform)" do
      tables = SpotMeta.__postgres_tables__()
      tokens = Enum.find(tables, &(&1.table == "tokens"))

      assert tokens.table == "tokens"
      assert tokens.extract == :tokens
      assert tokens.conflict_target == :index
      assert {:replace, _fields} = tokens.on_conflict
      assert is_function(tokens.transform, 1)
    end

    test "transform_tokens/1 is exported and callable" do
      assert function_exported?(SpotMeta, :transform_tokens, 1)

      test_tokens = [%{name: "TEST", evm_contract: nil}]
      assert [_] = SpotMeta.transform_tokens(test_tokens)
    end

    test "transform_tokens/1 converts evm_contract struct to map" do
      test_tokens = [
        %{
          index: 0,
          name: "USDC",
          evm_contract: %TestStruct{address: "0xabc", evm_extra_wei_decimals: 0}
        }
      ]

      transformed = SpotMeta.transform_tokens(test_tokens)
      token = hd(transformed)

      # evm_contract should be plain map (for JSONB)
      evm = token.evm_contract || token[:evm_contract]
      assert is_map(evm) or is_nil(evm)

      if evm do
        refute Map.has_key?(evm, :__struct__)
        refute Map.has_key?(evm, :__meta__)
      end
    end

    test "generates backwards-compatible postgres_table/0 (returns primary table)" do
      assert function_exported?(SpotMeta, :postgres_table, 0)
      assert SpotMeta.postgres_table() == "spot_pairs"
    end
  end

  describe "multi-table endpoint DSL - AllPerpMetas" do
    test "has __postgres_tables__/0 function" do
      assert function_exported?(AllPerpMetas, :__postgres_tables__, 0)
    end

    test "__postgres_tables__/0 returns list with two table configs" do
      tables = AllPerpMetas.__postgres_tables__()

      assert is_list(tables)
      assert length(tables) == 2
    end

    test "first table config is correct (perp_assets)" do
      tables = AllPerpMetas.__postgres_tables__()
      perp_assets = Enum.find(tables, &(&1.table == "perp_assets"))

      assert perp_assets.table == "perp_assets"
      assert perp_assets.extract == :universe
      assert perp_assets.conflict_target == :name
      assert {:replace, _fields} = perp_assets.on_conflict
      assert is_nil(perp_assets.transform)
    end

    test "second table config is correct (margin_tables with transform)" do
      tables = AllPerpMetas.__postgres_tables__()
      margin_tables = Enum.find(tables, &(&1.table == "margin_tables"))

      assert margin_tables.table == "margin_tables"
      assert margin_tables.extract == :margin_tables
      assert margin_tables.conflict_target == :id
      assert {:replace, _fields} = margin_tables.on_conflict
      assert is_function(margin_tables.transform, 1)
    end

    test "transform_margin_tables/1 is exported and callable" do
      assert function_exported?(AllPerpMetas, :transform_margin_tables, 1)

      test_tables = [%{id: 1, description: "test", margin_tiers: []}]
      assert [_] = AllPerpMetas.transform_margin_tables(test_tables)
    end

    test "transform_margin_tables/1 converts margin_tiers to list of maps" do
      test_tables = [
        %{
          id: 1,
          description: "Standard",
          margin_tiers: [
            %TierStruct{lower_bound: "0", max_leverage: "50"},
            %TierStruct{lower_bound: "100000", max_leverage: "25"}
          ]
        }
      ]

      transformed = AllPerpMetas.transform_margin_tables(test_tables)
      table = hd(transformed)

      # margin_tiers should be list of plain maps (for JSONB)
      tiers = table.margin_tiers || table[:margin_tiers]
      assert is_list(tiers)
      assert length(tiers) == 2

      tier1 = hd(tiers)
      assert is_map(tier1)
      refute Map.has_key?(tier1, :__struct__)
    end

    test "generates backwards-compatible postgres_table/0 (returns primary table)" do
      assert function_exported?(AllPerpMetas, :postgres_table, 0)
      assert AllPerpMetas.postgres_table() == "perp_assets"
    end
  end

  describe "DSL table configuration structure" do
    test "all table configs have required fields" do
      tables = SpotMeta.__postgres_tables__()

      Enum.each(tables, fn table ->
        assert Map.has_key?(table, :table)
        assert Map.has_key?(table, :extract)
        assert Map.has_key?(table, :conflict_target)
        assert Map.has_key?(table, :on_conflict)
        assert Map.has_key?(table, :transform)
        assert Map.has_key?(table, :fields)
      end)
    end

    test "primary table is extracted correctly" do
      # SpotMeta's primary table should be the first one
      assert SpotMeta.postgres_table() == "spot_pairs"

      # AllPerpMetas's primary table should be the first one
      assert AllPerpMetas.postgres_table() == "perp_assets"

      # UserFills single table is the primary
      assert UserFills.postgres_table() == "fills"
    end

    test "transform functions are properly referenced" do
      tables = SpotMeta.__postgres_tables__()
      tokens_config = Enum.find(tables, &(&1.table == "tokens"))

      # Transform should be a function reference
      assert is_function(tokens_config.transform, 1)

      # Transform should match the module's function
      test_data = [%{name: "TEST", evm_contract: nil}]
      assert SpotMeta.transform_tokens(test_data) == tokens_config.transform.(test_data)
    end
  end

  describe "endpoint metadata functions" do
    test "all endpoints have rate_limit_cost/0" do
      assert function_exported?(SpotMeta, :rate_limit_cost, 0)
      assert function_exported?(AllPerpMetas, :rate_limit_cost, 0)
      assert function_exported?(UserFills, :rate_limit_cost, 0)

      assert is_integer(SpotMeta.rate_limit_cost())
      assert is_integer(AllPerpMetas.rate_limit_cost())
      assert is_integer(UserFills.rate_limit_cost())
    end

    test "all endpoints have postgres_enabled?/0" do
      assert function_exported?(SpotMeta, :postgres_enabled?, 0)
      assert function_exported?(AllPerpMetas, :postgres_enabled?, 0)
      assert function_exported?(UserFills, :postgres_enabled?, 0)

      assert SpotMeta.postgres_enabled?() == true
      assert AllPerpMetas.postgres_enabled?() == true
      assert UserFills.postgres_enabled?() == true
    end

    test "all endpoints have build_request/*" do
      assert function_exported?(SpotMeta, :build_request, 0)
      assert function_exported?(AllPerpMetas, :build_request, 0)
      assert function_exported?(UserFills, :build_request, 1)
    end

    test "all endpoints have request functions" do
      assert function_exported?(SpotMeta, :request, 0)
      assert function_exported?(AllPerpMetas, :request, 0)
      assert function_exported?(UserFills, :request, 1)

      assert function_exported?(SpotMeta, :request!, 0)
      assert function_exported?(AllPerpMetas, :request!, 0)
      assert function_exported?(UserFills, :request!, 1)
    end
  end
end
