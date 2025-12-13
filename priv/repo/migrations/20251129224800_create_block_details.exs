defmodule Hyperliquid.Repo.Migrations.CreateBlockDetails do
  use Ecto.Migration

  def change do
    create table(:block_details, primary_key: false) do
      add :block_number, :bigint, null: false
      add :block_time, :bigint, null: false
      add :hash, :string
      add :prev_hash, :string
      add :proposer, :string
      # Full transaction list stored as JSONB
      add :txs, {:array, :map}

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:block_details, [:block_number])
    create index(:block_details, [:block_time])
    create index(:block_details, [:hash])
  end
end
