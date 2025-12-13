defmodule Hyperliquid.Api.Info.ExchangeStatus do
  @moduledoc """
  Exchange operational status.

  Returns current status of the exchange including maintenance mode and block height.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint

  ## Usage

      {:ok, status} = ExchangeStatus.request()
      if ExchangeStatus.operational?(status), do: IO.puts("Exchange is running")
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request: %{type: "exchangeStatus"},
    rate_limit_cost: 2,
    doc: "Retrieve exchange operational status",
    returns: "Status object with maintenance mode and block height"

  @type t :: %__MODULE__{
          time: non_neg_integer(),
          special_statuses: term()
        }

  @primary_key false
  embedded_schema do
    field(:time, :integer)
    field(:special_statuses, :map)
  end

  # ===================== Changeset =====================

  @doc """
  Creates a changeset for exchange status data.

  ## Parameters
    - `status`: The exchange status struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(status \\ %__MODULE__{}, attrs) do
    status
    |> cast(attrs, [:time, :special_statuses])
    |> validate_required([:time])
    |> validate_number(:time, greater_than_or_equal_to: 0)
  end

  @doc """
  Get server time as DateTime.

  ## Parameters
    - `status`: The exchange status struct

  ## Returns
    - `{:ok, DateTime.t()}` if valid
    - `{:error, :invalid_time}` if conversion fails
  """
  @spec server_datetime(t()) :: {:ok, DateTime.t()} | {:error, :invalid_time}
  def server_datetime(%__MODULE__{time: time}) do
    case DateTime.from_unix(time, :millisecond) do
      {:ok, dt} -> {:ok, dt}
      _ -> {:error, :invalid_time}
    end
  end

  @doc """
  Check if there are any special statuses.

  ## Parameters
    - `status`: The exchange status struct

  ## Returns
    - `boolean()`
  """
  @spec has_special_statuses?(t()) :: boolean()
  def has_special_statuses?(%__MODULE__{special_statuses: nil}), do: false

  def has_special_statuses?(%__MODULE__{special_statuses: statuses}) when statuses == %{},
    do: false

  def has_special_statuses?(%__MODULE__{}), do: true
end
