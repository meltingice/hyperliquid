defmodule Hyperliquid.Repo.Migrations.CreateTrades do
  use Ecto.Migration

  def change do
    create table(:trades, primary_key: false) do
      add :coin, :string, null: false
      add :side, :string, null: false
      add :px, :string, null: false
      add :sz, :string, null: false
      add :hash, :string
      add :time, :bigint, null: false
      # tid is 50-bit hash of (buyer_oid, seller_oid)
      # For globally unique trade id, use (block_time, coin, tid)
      add :tid, :bigint
      # users array [buyer, seller] transformed to separate fields
      add :buyer, :string
      add :seller, :string

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create index(:trades, [:coin, :time])
    create index(:trades, [:time])
    create index(:trades, [:buyer])
    create index(:trades, [:seller])
    create unique_index(:trades, [:tid], where: "tid IS NOT NULL")
  end
end
