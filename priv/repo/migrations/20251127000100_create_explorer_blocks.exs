defmodule Hyperliquid.Repo.Migrations.CreateExplorerBlocks do
  use Ecto.Migration

  def change do
    create table(:explorer_blocks, primary_key: false) do
      add :height, :bigint, null: false
      add :time, :bigint, null: false
      add :hash, :string
      add :proposer, :string
      add :num_txs, :integer

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:explorer_blocks, [:height])
    create index(:explorer_blocks, [:time])
  end
end
