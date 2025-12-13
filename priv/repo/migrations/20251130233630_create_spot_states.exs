defmodule Hyperliquid.Repo.Migrations.CreateSpotStates do
  use Ecto.Migration

  def change do
    create table(:spot_states, primary_key: false) do
      add :user, :string, null: false
      add :balances, {:array, :map}, default: []
      add :evm_escrows, {:array, :map}

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create index(:spot_states, [:user])
    create index(:spot_states, [:inserted_at])
  end
end
