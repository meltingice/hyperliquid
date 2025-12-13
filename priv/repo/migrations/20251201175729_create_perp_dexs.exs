defmodule Hyperliquid.Repo.Migrations.CreatePerpDexs do
  use Ecto.Migration

  def change do
    create table(:perp_dexs, primary_key: false) do
      # Unique identifier for the DEX
      add :name, :string, primary_key: true

      # Static/rarely changing fields
      add :full_name, :string, null: false
      add :deployer, :string, null: false
      add :oracle_updater, :string
      add :fee_recipient, :string
      add :deployer_fee_scale, :string
      add :last_deployer_fee_scale_change_time, :string

      # Dynamic fields stored as JSONB (can change over time)
      # Array of [asset_name, streaming_oi_cap] tuples
      add :asset_to_streaming_oi_cap, :jsonb, default: "[]"
      # Array of [function_name, [addresses]] tuples
      add :sub_deployers, :jsonb, default: "[]"

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:perp_dexs, [:deployer])
    create index(:perp_dexs, [:inserted_at])
  end
end
