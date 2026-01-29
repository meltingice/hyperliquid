defmodule Hyperliquid.Api.Info.AllBorrowLendReserveStates do
  @moduledoc """
  Borrow/lend reserve state data.

  Returns reserve states including rates, balances, utilization, and oracle prices
  for all available lending markets.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint

  ## Usage

      {:ok, states} = AllBorrowLendReserveStates.request()
      {:ok, reserve} = AllBorrowLendReserveStates.get_reserve(states, 0)
      count = AllBorrowLendReserveStates.count(states)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "allBorrowLendReserveStates",
    params: [],
    rate_limit_cost: 2,
    doc: "Retrieve borrow/lend reserve states",
    returns: "Reserve states with rates, balances, and utilization"

  @type t :: %__MODULE__{
          reserves: [ReserveState.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :reserves, ReserveState, primary_key: false do
      @moduledoc "State for a single lending reserve."

      field(:index, :integer)
      field(:borrow_yearly_rate, :string)
      field(:supply_yearly_rate, :string)
      field(:balance, :string)
      field(:utilization, :string)
      field(:oracle_px, :string)
      field(:ltv, :string)
      field(:total_supplied, :string)
      field(:total_borrowed, :string)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{reserves: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for borrow/lend reserve states data.

  ## Parameters
    - `states`: The reserve states struct
    - `attrs`: Map with reserves list from API response

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(states \\ %__MODULE__{}, attrs)

  def changeset(states, %{reserves: attrs}) when is_list(attrs) do
    parsed_reserves = Enum.map(attrs, &parse_reserve/1)

    states
    |> cast(%{}, [])
    |> put_embed(:reserves, parsed_reserves)
  end

  def changeset(states, attrs) do
    states
    |> cast(attrs, [])
    |> put_embed(:reserves, [])
  end

  defp parse_reserve([index, state]) when is_integer(index) and is_map(state) do
    %__MODULE__.ReserveState{
      index: index,
      borrow_yearly_rate: state["borrow_yearly_rate"] || state["borrowYearlyRate"],
      supply_yearly_rate: state["supply_yearly_rate"] || state["supplyYearlyRate"],
      balance: state["balance"],
      utilization: state["utilization"],
      oracle_px: state["oracle_px"] || state["oraclePx"],
      ltv: state["ltv"],
      total_supplied: state["total_supplied"] || state["totalSupplied"],
      total_borrowed: state["total_borrowed"] || state["totalBorrowed"]
    }
  end

  defp parse_reserve(_) do
    %__MODULE__.ReserveState{
      index: -1,
      borrow_yearly_rate: "0",
      supply_yearly_rate: "0",
      balance: "0",
      utilization: "0",
      oracle_px: "0",
      ltv: "0",
      total_supplied: "0",
      total_borrowed: "0"
    }
  end

  # ===================== Helpers =====================

  @doc """
  Get reserve state by index.

  ## Parameters
    - `states`: The reserve states struct
    - `index`: Reserve index

  ## Returns
    - `{:ok, ReserveState.t()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec get_reserve(t(), integer()) :: {:ok, map()} | {:error, :not_found}
  def get_reserve(%__MODULE__{reserves: reserves}, index) when is_integer(index) do
    case Enum.find(reserves, &(&1.index == index)) do
      nil -> {:error, :not_found}
      reserve -> {:ok, reserve}
    end
  end

  @doc """
  Get the number of reserves.

  ## Parameters
    - `states`: The reserve states struct

  ## Returns
    - `non_neg_integer()`
  """
  @spec count(t()) :: non_neg_integer()
  def count(%__MODULE__{reserves: reserves}) do
    length(reserves)
  end
end
