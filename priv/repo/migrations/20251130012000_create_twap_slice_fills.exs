defmodule Hyperliquid.Repo.Migrations.CreateTwapSliceFills do
  use Ecto.Migration

  def change do
    create table(:twap_slice_fills, primary_key: false) do
      add :user, :string, null: false
      add :twap_id, :bigint
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

    create unique_index(:twap_slice_fills, [:user, :tid], where: "tid IS NOT NULL")
    create index(:twap_slice_fills, [:user, :twap_id])
    create index(:twap_slice_fills, [:user, :time])
    create index(:twap_slice_fills, [:time])
  end
end
