defmodule Hyperliquid.Repo.Migrations.CreateClearinghouseStates do
  use Ecto.Migration

  def change do
    create table(:clearinghouse_states, primary_key: false) do
      add :user, :string, null: false
      add :dex, :string, default: ""
      add :margin_summary, :map
      add :cross_margin_summary, :map
      add :withdrawable, :string
      add :asset_positions, {:array, :map}

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create index(:clearinghouse_states, [:user])
    create index(:clearinghouse_states, [:user, :dex])
    create index(:clearinghouse_states, [:inserted_at])
  end
end
