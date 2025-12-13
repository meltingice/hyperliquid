defmodule Hyperliquid.Api.Info.AlignedQuoteTokenInfo do
  @moduledoc """
  Information about aligned quote tokens.

  Returns alignment status, mint supply, and predicted rates for quote tokens.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint

  ## Usage

      {:ok, info} = AlignedQuoteTokenInfo.request(0)
      AlignedQuoteTokenInfo.aligned?(info)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "alignedQuoteTokenInfo",
    params: [:token],
    rate_limit_cost: 2,
    doc: "Retrieve information about aligned quote tokens",
    returns: "Alignment status, mint supply, and predicted rates"

  @type t :: %__MODULE__{
          is_aligned: boolean(),
          first_aligned_time: non_neg_integer() | nil,
          evm_minted_supply: String.t(),
          daily_amount_owed: [DailyAmount.t()],
          predicted_rate: String.t()
        }

  @primary_key false
  embedded_schema do
    field(:is_aligned, :boolean)
    field(:first_aligned_time, :integer)
    field(:evm_minted_supply, :string)
    field(:predicted_rate, :string)

    embeds_many :daily_amount_owed, DailyAmount, primary_key: false do
      @moduledoc "Daily amount owed entry."

      field(:date, :string)
      field(:amount, :string)
    end
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for aligned quote token info data.

  ## Parameters
    - `info`: The aligned quote token info struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(info \\ %__MODULE__{}, attrs) do
    # Transform daily_amount_owed from array format to map format
    transformed_attrs = transform_daily_amounts(attrs)

    info
    |> cast(transformed_attrs, [
      :is_aligned,
      :first_aligned_time,
      :evm_minted_supply,
      :predicted_rate
    ])
    |> cast_embed(:daily_amount_owed, with: &daily_amount_changeset/2)
    |> validate_required([:is_aligned, :evm_minted_supply, :predicted_rate])
  end

  # ===================== Custom Response Parser =====================

  @doc """
  Parse and validate the API response.

  Handles null responses from the API.
  """
  @spec parse_response(map() | nil) :: {:ok, t() | nil} | {:error, term()}
  def parse_response(nil), do: {:ok, nil}

  def parse_response(data) when is_map(data) do
    changeset(%__MODULE__{}, data)
    |> apply_action(:validate)
  end

  def parse_response(_), do: {:error, :invalid_response_format}

  defp transform_daily_amounts(attrs) do
    daily_amounts = attrs["dailyAmountOwed"] || attrs[:daily_amount_owed] || []

    transformed =
      Enum.map(daily_amounts, fn
        [date, amount] -> %{"date" => date, "amount" => amount}
        %{"date" => _, "amount" => _} = m -> m
        %{date: _, amount: _} = m -> m
        _ -> %{"date" => "", "amount" => "0"}
      end)

    attrs
    |> Map.put("daily_amount_owed", transformed)
    |> Map.delete("dailyAmountOwed")
  end

  defp daily_amount_changeset(daily_amount, attrs) do
    daily_amount
    |> cast(attrs, [:date, :amount])
    |> validate_required([:date, :amount])
  end

  # ===================== Helpers =====================

  @doc """
  Check if the token is aligned.

  ## Parameters
    - `info`: The aligned quote token info struct

  ## Returns
    - `boolean()`
  """
  @spec aligned?(t()) :: boolean()
  def aligned?(%__MODULE__{is_aligned: is_aligned}) do
    is_aligned == true
  end

  @doc """
  Get the total amount owed across all days.

  ## Parameters
    - `info`: The aligned quote token info struct

  ## Returns
    - `{:ok, Decimal.t()}` - Total amount
    - `{:error, :parse_error}` - If parsing fails
  """
  @spec total_amount_owed(t()) :: {:ok, float()} | {:error, :parse_error}
  def total_amount_owed(%__MODULE__{daily_amount_owed: amounts}) do
    try do
      total =
        amounts
        |> Enum.map(&String.to_float(&1.amount))
        |> Enum.sum()

      {:ok, total}
    rescue
      _ -> {:error, :parse_error}
    end
  end

  @doc """
  Get the amount owed for a specific date.

  ## Parameters
    - `info`: The aligned quote token info struct
    - `date`: Date string to find

  ## Returns
    - `{:ok, String.t()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec amount_for_date(t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def amount_for_date(%__MODULE__{daily_amount_owed: amounts}, date) when is_binary(date) do
    case Enum.find(amounts, &(&1.date == date)) do
      nil -> {:error, :not_found}
      %{amount: amount} -> {:ok, amount}
    end
  end
end
