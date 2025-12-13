defmodule Hyperliquid.Repo.Migrations.CreateFills do
  use Ecto.Migration

  def change do
    create table(:fills, primary_key: false) do
      add :user, :string, null: false
      add :coin, :string, null: false
      add :px, :string
      add :sz, :string
      add :side, :string
      add :time, :bigint, null: false
      add :start_position, :string
      add :dir, :string
      add :closed_pnl, :string
      add :hash, :string
      add :oid, :bigint
      add :crossed, :boolean
      add :fee, :string
      add :tid, :bigint
      add :fee_token, :string

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:fills, [:user, :tid], where: "tid IS NOT NULL")
    create index(:fills, [:user, :time])
    create index(:fills, [:user, :coin])
    create index(:fills, [:time])
    create index(:fills, [:hash])
  end
end
