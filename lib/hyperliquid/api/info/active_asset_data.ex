defmodule Hyperliquid.Api.Info.ActiveAssetData do
  @moduledoc """
  Active trading data for a specific asset and user.

  Returns leverage, max trade sizes, available balance, and mark price
  for a specific coin and user combination.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/perpetuals

  ## Usage

      {:ok, data} = ActiveAssetData.request("0x1234...", "BTC")
      ActiveAssetData.cross_margin?(data)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "activeAssetData",
    params: [:user, :coin],
    rate_limit_cost: 2,
    doc: "Retrieve active trading data for a specific asset and user",
    returns: "Leverage, max trade sizes, available balance, and mark price"

  @type t :: %__MODULE__{
          leverage: Leverage.t(),
          max_trade_szs: [String.t()],
          available_to_trade: [String.t()],
          mark_px: String.t()
        }

  @primary_key false
  embedded_schema do
    embeds_one :leverage, Leverage, primary_key: false do
      @moduledoc "Leverage configuration."

      field(:type, :string)
      field(:value, :integer)
      field(:raw_usd, :string)
    end

    field(:max_trade_szs, {:array, :string})
    field(:available_to_trade, {:array, :string})
    field(:mark_px, :string)
  end

  # ===================== Changeset =====================

  @doc """
  Creates a changeset for active asset data.

  ## Parameters
    - `data`: The active asset data struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, [:max_trade_szs, :available_to_trade, :mark_px])
    |> cast_embed(:leverage, with: &leverage_changeset/2)
    |> validate_required([:mark_px])
  end

  defp leverage_changeset(leverage, attrs) do
    leverage
    |> cast(attrs, [:type, :value, :raw_usd])
    |> validate_required([:type, :value])
    |> validate_inclusion(:type, ["cross", "isolated"])
    |> validate_number(:value, greater_than_or_equal_to: 1)
  end

  # ===================== Helpers =====================

  @doc """
  Check if using cross margin.

  ## Parameters
    - `data`: The active asset data struct

  ## Returns
    - `boolean()`
  """
  @spec cross_margin?(t()) :: boolean()
  def cross_margin?(%__MODULE__{leverage: %{type: type}}) do
    type == "cross"
  end

  @doc """
  Check if using isolated margin.

  ## Parameters
    - `data`: The active asset data struct

  ## Returns
    - `boolean()`
  """
  @spec isolated_margin?(t()) :: boolean()
  def isolated_margin?(%__MODULE__{leverage: %{type: type}}) do
    type == "isolated"
  end

  @doc """
  Get the leverage value.

  ## Parameters
    - `data`: The active asset data struct

  ## Returns
    - Integer leverage value
  """
  @spec leverage_value(t()) :: integer()
  def leverage_value(%__MODULE__{leverage: %{value: value}}) do
    value
  end

  @doc """
  Get the max buy size.

  ## Parameters
    - `data`: The active asset data struct

  ## Returns
    - `{:ok, String.t()}` if available
    - `{:error, :not_available}` if not available
  """
  @spec max_buy_size(t()) :: {:ok, String.t()} | {:error, :not_available}
  def max_buy_size(%__MODULE__{max_trade_szs: [buy | _]}) do
    {:ok, buy}
  end

  def max_buy_size(_), do: {:error, :not_available}

  @doc """
  Get the max sell size.

  ## Parameters
    - `data`: The active asset data struct

  ## Returns
    - `{:ok, String.t()}` if available
    - `{:error, :not_available}` if not available
  """
  @spec max_sell_size(t()) :: {:ok, String.t()} | {:error, :not_available}
  def max_sell_size(%__MODULE__{max_trade_szs: [_, sell | _]}) do
    {:ok, sell}
  end

  def max_sell_size(_), do: {:error, :not_available}
end
