defmodule Hyperliquid.Repo.Migrations.CreateCandles do
  use Ecto.Migration

  def change do
    create table(:candles, primary_key: false) do
      # Symbol
      add :coin, :string, null: false
      # Interval (1m, 5m, 1h, etc)
      add :interval, :string, null: false
      # Candle start time (ms)
      add :open_time, :bigint, null: false
      # Candle close time (ms)
      add :close_time, :bigint
      # OHLCV
      add :open, :string
      add :high, :string
      add :low, :string
      add :close, :string
      add :volume, :string
      # Number of trades
      add :num_trades, :integer

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create unique_index(:candles, [:coin, :interval, :open_time])
    create index(:candles, [:coin, :interval])
    create index(:candles, [:open_time])
  end
end
