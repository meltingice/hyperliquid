defmodule Hyperliquid.Repo.Migrations.CreateMarginTables do
  use Ecto.Migration

  def change do
    create table(:margin_tables, primary_key: false) do
      # Margin table ID is the unique identifier
      add :id, :integer, primary_key: true

      add :description, :string
      # Margin tiers stored as JSONB array
      add :margin_tiers, :jsonb, null: false

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end
  end
end
