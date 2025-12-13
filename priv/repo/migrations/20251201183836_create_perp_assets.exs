defmodule Hyperliquid.Repo.Migrations.CreatePerpAssets do
  use Ecto.Migration

  def change do
    create table(:perp_assets, primary_key: false) do
      # Unique identifier - includes DEX prefix for builder DEXs (e.g., "xyz:XYZ100")
      # Main DEX assets have no prefix (e.g., "BTC", "ETH")
      add :name, :string, primary_key: true

      # Core asset metadata
      add :sz_decimals, :integer, null: false
      add :max_leverage, :integer, null: false
      add :margin_table_id, :integer, null: false

      # Optional flags (can change over time)
      add :only_isolated, :boolean, default: false
      add :is_delisted, :boolean, default: false
      add :margin_mode, :string

      # Growth mode info (for builder DEX assets)
      add :growth_mode, :string
      add :last_growth_mode_change_time, :string

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    # Index for finding assets by their DEX prefix
    # Main DEX assets don't have a prefix, builder DEX assets have "dex_name:" prefix
    create index(:perp_assets, [:name])
    create index(:perp_assets, [:is_delisted])
    create index(:perp_assets, [:inserted_at])
  end
end
