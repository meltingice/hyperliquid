defmodule Hyperliquid.Repo.Migrations.CreateSpotPairsAndTokens do
  use Ecto.Migration

  def change do
    # Tokens table - stores individual token metadata
    create table(:tokens, primary_key: false) do
      # Token index is the unique identifier
      add :index, :integer, primary_key: true

      add :name, :string, null: false
      add :sz_decimals, :integer, null: false
      add :wei_decimals, :integer, null: false
      add :token_id, :string
      add :is_canonical, :boolean, default: false
      add :full_name, :string
      add :deployer_trading_fee_share, :string

      # EVM contract info stored as JSONB (may be null)
      add :evm_contract, :jsonb

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:tokens, [:name])
    create index(:tokens, [:is_canonical])

    # Spot pairs table - stores trading pairs
    create table(:spot_pairs, primary_key: false) do
      # Pair index is the unique identifier
      add :index, :integer, primary_key: true

      # Original name from API (e.g., "PURR/USDC", "@1", "@2")
      add :name, :string, null: false

      # Computed display name (e.g., "PURR/USDC", "HFUN/USDC")
      add :display_name, :string, null: false

      # Token indices that make up this pair [base_token_index, quote_token_index]
      add :tokens, {:array, :integer}, null: false

      add :is_canonical, :boolean, default: false

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:spot_pairs, [:name])
    create index(:spot_pairs, [:display_name])
    create index(:spot_pairs, [:is_canonical])
  end
end
