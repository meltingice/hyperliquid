defmodule Hyperliquid.Api.Info.Liquidatable do
  @moduledoc """
  Liquidatable positions.

  Returns list of positions that can be liquidated.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint

  ## Usage

      {:ok, liquidatable} = Liquidatable.request()
      btc_positions = Liquidatable.by_coin(liquidatable, "BTC")
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "liquidatable",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve liquidatable positions",
    returns: "List of positions that can be liquidated"

  @type t :: %__MODULE__{
          positions: [Position.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :positions, Position, primary_key: false do
      @moduledoc "Liquidatable position."

      field(:user, :string)
      field(:coin, :string)
      field(:szi, :string)
      field(:leverage, :integer)
      field(:mark_px, :string)
      field(:liq_px, :string)
      field(:margin_used, :string)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{positions: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for liquidatable data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(liquidatable \\ %__MODULE__{}, attrs) do
    liquidatable
    |> cast(attrs, [])
    |> cast_embed(:positions, with: &position_changeset/2)
  end

  defp position_changeset(position, attrs) do
    position
    |> cast(attrs, [:user, :coin, :szi, :leverage, :mark_px, :liq_px, :margin_used])
    |> validate_required([:user, :coin, :szi, :leverage, :mark_px, :liq_px])
  end

  # ===================== Helpers =====================

  @doc """
  Get positions by coin.
  """
  @spec by_coin(t(), String.t()) :: [map()]
  def by_coin(%__MODULE__{positions: positions}, coin) do
    Enum.filter(positions, &(&1.coin == coin))
  end

  @doc """
  Get total count.
  """
  @spec count(t()) :: non_neg_integer()
  def count(%__MODULE__{positions: positions}), do: length(positions)
end
