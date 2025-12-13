defmodule Hyperliquid.Api.Info.Portfolio do
  @moduledoc """
  User portfolio performance data.

  Returns historical account value, PnL, and volume data across multiple
  timeframes (day, week, month, allTime) for both combined and perp-only views.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#query-a-users-portfolio
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "portfolio",
    params: [:user],
    rate_limit_cost: 2,
    doc: "Retrieve user portfolio performance data",
    returns: "Historical account value, PnL, and volume data"

  @type t :: %__MODULE__{
          periods: [Period.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :periods, Period, primary_key: false do
      @moduledoc "Portfolio data for a specific time period."

      field(:name, :string)

      embeds_one :data, PeriodData, primary_key: false do
        @moduledoc "Portfolio metrics for the period."

        # Each entry is [timestamp_ms, value_string]
        field(:account_value_history, {:array, :map})
        field(:pnl_history, {:array, :map})
        field(:vlm, :string)
      end
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    parsed_periods = Enum.map(data, &parse_period/1)
    %{periods: parsed_periods}
  end

  def preprocess(data), do: data

  defp parse_period([name, data]) when is_binary(name) and is_map(data) do
    %{
      name: name,
      data: parse_period_data(data)
    }
  end

  defp parse_period(_), do: %{name: "", data: nil}

  defp parse_period_data(data) when is_map(data) do
    %{
      account_value_history:
        parse_history(data["accountValueHistory"] || data[:account_value_history] || []),
      pnl_history: parse_history(data["pnlHistory"] || data[:pnl_history] || []),
      vlm: data["vlm"] || data[:vlm] || "0"
    }
  end

  defp parse_history(history) when is_list(history) do
    Enum.map(history, fn
      [timestamp, value] -> %{timestamp: timestamp, value: value}
      entry -> entry
    end)
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for portfolio data.

  ## Parameters
    - `portfolio`: The portfolio struct
    - `attrs`: Map with periods key

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(portfolio \\ %__MODULE__{}, attrs) do
    portfolio
    |> cast(attrs, [])
    |> cast_embed(:periods, with: &period_changeset/2)
  end

  defp period_changeset(period, attrs) do
    period
    |> cast(attrs, [:name])
    |> cast_embed(:data, with: &period_data_changeset/2)
  end

  defp period_data_changeset(data, attrs) do
    data
    |> cast(attrs, [:account_value_history, :pnl_history, :vlm])
  end

  # ===================== Helpers =====================

  @doc """
  Get data for a specific period.

  ## Parameters
    - `portfolio`: The portfolio struct
    - `period_name`: Period name (e.g., "day", "week", "month", "allTime", "perpDay", etc.)

  ## Returns
    - `{:ok, PeriodData.t()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec get_period(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_period(%__MODULE__{periods: periods}, period_name) when is_binary(period_name) do
    case Enum.find(periods, &(&1.name == period_name)) do
      nil -> {:error, :not_found}
      %{data: data} -> {:ok, data}
    end
  end

  @doc """
  Get all available period names.

  ## Parameters
    - `portfolio`: The portfolio struct

  ## Returns
    - List of period names
  """
  @spec period_names(t()) :: [String.t()]
  def period_names(%__MODULE__{periods: periods}) do
    Enum.map(periods, & &1.name)
  end

  @doc """
  Get the latest account value for a period.

  ## Parameters
    - `portfolio`: The portfolio struct
    - `period_name`: Period name

  ## Returns
    - `{:ok, String.t()}` if found
    - `{:error, :not_found}` if not found or no history
  """
  @spec latest_account_value(t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def latest_account_value(%__MODULE__{} = portfolio, period_name) do
    with {:ok, %{account_value_history: history}} <- get_period(portfolio, period_name),
         %{value: value} <- List.last(history) do
      {:ok, value}
    else
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Get the latest PnL for a period.

  ## Parameters
    - `portfolio`: The portfolio struct
    - `period_name`: Period name

  ## Returns
    - `{:ok, String.t()}` if found
    - `{:error, :not_found}` if not found or no history
  """
  @spec latest_pnl(t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def latest_pnl(%__MODULE__{} = portfolio, period_name) do
    with {:ok, %{pnl_history: history}} <- get_period(portfolio, period_name),
         %{value: value} <- List.last(history) do
      {:ok, value}
    else
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Get volume for a period.

  ## Parameters
    - `portfolio`: The portfolio struct
    - `period_name`: Period name

  ## Returns
    - `{:ok, String.t()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec volume(t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def volume(%__MODULE__{} = portfolio, period_name) do
    case get_period(portfolio, period_name) do
      {:ok, %{vlm: vlm}} -> {:ok, vlm}
      error -> error
    end
  end
end
