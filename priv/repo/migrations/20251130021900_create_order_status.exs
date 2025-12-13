defmodule Hyperliquid.Repo.Migrations.CreateOrderStatus do
  use Ecto.Migration

  def change do
    create table(:order_status, primary_key: false) do
      add :user, :string, null: false
      add :oid, :bigint, null: false
      add :status, :string
      add :coin, :string
      add :side, :string
      add :limit_px, :string
      add :sz, :string
      add :timestamp, :bigint
      add :orig_sz, :string
      add :cloid, :string

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:order_status, [:user, :oid])
    create index(:order_status, [:user, :status])
    create index(:order_status, [:oid])
  end
end
