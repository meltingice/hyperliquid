defmodule Hyperliquid.Repo.Migrations.CreateUserSnapshots do
  use Ecto.Migration

  def change do
    create table(:user_snapshots, primary_key: false) do
      add :user, :string, null: false
      add :server_time, :bigint, null: false

      # Complex nested structures stored as JSONB
      add :clearinghouse_state, :map
      add :open_orders, {:array, :map}
      add :spot_state, :map
      add :twap_states, {:array, :map}

      add :inserted_at, :utc_datetime_usec, null: false
    end

    # Primary lookup by user
    create index(:user_snapshots, [:user])
    create index(:user_snapshots, [:user, :server_time])
    create index(:user_snapshots, [:server_time])
  end
end
