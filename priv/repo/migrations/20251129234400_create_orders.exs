defmodule Hyperliquid.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :user, :string, null: false
      add :coin, :string, null: false
      add :side, :string
      add :limit_px, :string
      add :sz, :string
      add :oid, :bigint, null: false
      add :timestamp, :bigint
      add :orig_sz, :string
      add :cloid, :string
      # For order status queries
      add :status, :string

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:orders, [:user, :oid])
    create index(:orders, [:user])
    create index(:orders, [:coin])
    create index(:orders, [:oid])
    create index(:orders, [:timestamp])
  end
end
