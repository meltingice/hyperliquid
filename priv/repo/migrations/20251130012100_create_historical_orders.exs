defmodule Hyperliquid.Repo.Migrations.CreateHistoricalOrders do
  use Ecto.Migration

  def change do
    create table(:historical_orders, primary_key: false) do
      add :user, :string, null: false
      add :coin, :string, null: false
      add :side, :string
      add :limit_px, :string
      add :sz, :string
      add :oid, :bigint, null: false
      add :timestamp, :bigint
      add :orig_sz, :string
      add :cloid, :string
      add :order_type, :string
      add :tif, :string
      add :reduce_only, :boolean
      add :status, :string
      add :status_timestamp, :bigint

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:historical_orders, [:user, :oid])
    create index(:historical_orders, [:user, :status])
    create index(:historical_orders, [:user, :coin])
    create index(:historical_orders, [:timestamp])
  end
end
