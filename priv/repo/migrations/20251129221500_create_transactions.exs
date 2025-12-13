defmodule Hyperliquid.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :hash, :string, null: false
      add :block, :bigint
      add :block_time, :bigint
      add :error, :string
      # Full transaction data stored as JSONB
      add :tx, :map

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:transactions, [:hash])
    create index(:transactions, [:block])
    create index(:transactions, [:block_time])
  end
end
