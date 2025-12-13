defmodule Hyperliquid.Api.Info.IsVip do
  @moduledoc """
  VIP status check for a user.

  Returns whether a user has VIP status and associated benefits.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "isVip",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Check VIP status for a user",
    returns: "VIP status with tier and fee rates if applicable"

  @type t :: %__MODULE__{
          is_vip: boolean(),
          vip_tier: non_neg_integer() | nil,
          maker_rate: String.t() | nil,
          taker_rate: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    field(:is_vip, :boolean)
    field(:vip_tier, :integer)
    field(:maker_rate, :string)
    field(:taker_rate, :string)
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for VIP status data.

  ## Parameters
    - `vip`: The VIP status struct
    - `attrs`: Map or boolean value from API response

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map() | boolean()) :: Ecto.Changeset.t()
  def changeset(vip \\ %__MODULE__{}, attrs)

  def changeset(vip, attrs) when is_boolean(attrs) do
    # Simple boolean response
    vip
    |> cast(%{is_vip: attrs}, [:is_vip])
    |> validate_required([:is_vip])
  end

  def changeset(vip, nil) do
    # Nil response means not VIP
    vip
    |> cast(%{is_vip: false}, [:is_vip])
    |> validate_required([:is_vip])
  end

  def changeset(vip, attrs) when is_map(attrs) do
    vip
    |> cast(attrs, [:is_vip, :vip_tier, :maker_rate, :taker_rate])
    |> validate_required([:is_vip])
    |> validate_number(:vip_tier, greater_than_or_equal_to: 0)
  end

  # ===================== Custom Response Parser =====================

  @doc """
  Parse and validate the API response.

  Handles boolean responses (true/false/nil) from the API.
  """
  @spec parse_response(boolean() | nil | map()) :: {:ok, t()} | {:error, term()}
  def parse_response(data) when is_boolean(data) or is_nil(data) do
    changeset(%__MODULE__{}, data)
    |> apply_action(:validate)
  end

  def parse_response(data) when is_map(data) do
    changeset(%__MODULE__{}, data)
    |> apply_action(:validate)
  end

  def parse_response(_), do: {:error, :invalid_response_format}

  @doc """
  Check if user is a VIP.

  ## Parameters
    - `vip`: The VIP status struct

  ## Returns
    - `boolean()`
  """
  @spec vip?(t()) :: boolean()
  def vip?(%__MODULE__{is_vip: is_vip}) do
    is_vip == true
  end

  @doc """
  Get the VIP tier.

  ## Parameters
    - `vip`: The VIP status struct

  ## Returns
    - `{:ok, non_neg_integer()}` if VIP with tier
    - `{:error, :not_vip}` if not VIP
    - `{:error, :no_tier}` if VIP but no tier info
  """
  @spec tier(t()) :: {:ok, non_neg_integer()} | {:error, :not_vip | :no_tier}
  def tier(%__MODULE__{is_vip: false}), do: {:error, :not_vip}
  def tier(%__MODULE__{vip_tier: nil}), do: {:error, :no_tier}
  def tier(%__MODULE__{vip_tier: tier}), do: {:ok, tier}

  @doc """
  Get fee rates if available.

  ## Parameters
    - `vip`: The VIP status struct

  ## Returns
    - `{:ok, %{maker: String.t(), taker: String.t()}}` if available
    - `{:error, :not_available}` if not available
  """
  @spec fee_rates(t()) :: {:ok, map()} | {:error, :not_available}
  def fee_rates(%__MODULE__{maker_rate: maker, taker_rate: taker})
      when is_binary(maker) and is_binary(taker) do
    {:ok, %{maker: maker, taker: taker}}
  end

  def fee_rates(_), do: {:error, :not_available}
end
