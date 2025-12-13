defmodule Hyperliquid.Api.Info.MaxBuilderFee do
  @moduledoc """
  Maximum builder fee for a user.

  Returns the max fee a builder can charge.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "maxBuilderFee",
    params: [:user, :builder],
    rate_limit_cost: 1,
    doc: "Retrieve maximum builder fee for a user",
    returns: "Maximum fee a builder can charge"

  @type t :: %__MODULE__{
          max_fee: float()
        }

  @primary_key false
  embedded_schema do
    field(:max_fee, :float)
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for max builder fee data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(fee \\ %__MODULE__{}, attrs) do
    fee
    |> cast(attrs, [:max_fee])
    |> validate_required([:max_fee])
  end

  # ===================== Custom Response Parser =====================

  @doc false
  @spec parse_response(number()) :: {:ok, t()} | {:error, term()}
  def parse_response(data) when is_number(data) do
    changeset(%__MODULE__{}, %{max_fee: data})
    |> apply_action(:validate)
  end

  def parse_response(_), do: {:error, :invalid_response_format}

  # ===================== Helpers =====================

  @doc """
  Get fee value.
  """
  @spec fee(t()) :: float()
  def fee(%__MODULE__{max_fee: fee}), do: fee
end
