defmodule Hyperliquid.Api.Info.TwapHistory do
  @moduledoc """
  TWAP order history for a user.

  Returns historical TWAP (Time-Weighted Average Price) orders.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "twapHistory",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Retrieve user's TWAP order history",
    returns: "Historical TWAP orders"

  @type t :: %__MODULE__{
          records: [Record.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :records, Record, primary_key: false do
      @moduledoc "TWAP history record."

      field(:time, :integer)
      field(:twap_id, :integer)

      embeds_one :state, State, primary_key: false do
        @moduledoc "TWAP order state."

        field(:coin, :string)
        field(:executed_ntl, :string)
        field(:executed_sz, :string)
        field(:minutes, :integer)
        field(:randomize, :boolean)
        field(:reduce_only, :boolean)
        field(:side, :string)
        field(:sz, :string)
        field(:timestamp, :integer)
        field(:user, :string)
      end

      embeds_one :status, Status, primary_key: false do
        @moduledoc "TWAP order status."

        field(:status, :string)
        field(:description, :string)
      end
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{records: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for TWAP history data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(history \\ %__MODULE__{}, attrs) do
    history
    |> cast(attrs, [])
    |> cast_embed(:records, with: &record_changeset/2)
  end

  defp record_changeset(record, attrs) do
    record
    |> cast(attrs, [:time, :twap_id])
    |> cast_embed(:state, with: &state_changeset/2)
    |> cast_embed(:status, with: &status_changeset/2)
    |> validate_required([:time])
  end

  defp state_changeset(state, attrs) do
    state
    |> cast(attrs, [
      :coin,
      :executed_ntl,
      :executed_sz,
      :minutes,
      :randomize,
      :reduce_only,
      :side,
      :sz,
      :timestamp,
      :user
    ])
    |> validate_required([:coin, :side, :sz, :minutes, :timestamp])
  end

  defp status_changeset(status, attrs) do
    status
    |> cast(attrs, [:status, :description])
    |> validate_required([:status])
  end

  # ===================== Helpers =====================

  @doc """
  Get records by coin.
  """
  @spec by_coin(t(), String.t()) :: [map()]
  def by_coin(%__MODULE__{records: records}, coin) do
    Enum.filter(records, &(&1.state && &1.state.coin == coin))
  end

  @doc """
  Get active records.
  """
  @spec active(t()) :: [map()]
  def active(%__MODULE__{records: records}) do
    Enum.filter(records, &(&1.status && &1.status.status == "activated"))
  end
end
