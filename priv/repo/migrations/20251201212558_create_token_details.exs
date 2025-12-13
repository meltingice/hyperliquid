defmodule Hyperliquid.Repo.Migrations.CreateTokenDetails do
  use Ecto.Migration

  def change do
    create table(:token_details, primary_key: false) do
      # Token ID is the unique identifier (hex string like "0xc1fb593aeffbeb02f85e0308e9956a90")
      add :token_id, :string, primary_key: true

      add :name, :string, null: false
      add :max_supply, :string
      add :total_supply, :string
      add :circulating_supply, :string
      add :sz_decimals, :integer
      add :wei_decimals, :integer

      # Price info
      add :mid_px, :string
      add :mark_px, :string
      add :prev_day_px, :string

      # Genesis/deploy info
      add :genesis, :jsonb
      add :deployer, :string
      add :deploy_gas, :string
      add :deploy_time, :string

      # Other fields
      add :seeded_usdc, :string
      add :non_circulating_user_balances, :jsonb
      add :future_emissions, :string

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:token_details, [:name])
    create index(:token_details, [:deployer])
  end
end
