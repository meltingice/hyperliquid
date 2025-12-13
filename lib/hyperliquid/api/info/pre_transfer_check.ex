defmodule Hyperliquid.Api.Info.PreTransferCheck do
  @moduledoc """
  Pre-transfer validation check.

  Validates whether a transfer can be made before executing it.
  Returns information about transfer eligibility and any restrictions.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "preTransferCheck",
    params: [:user, :source],
    rate_limit_cost: 1,
    doc: "Check user existence before transfer",
    returns: "User existence and sanction status"

  @type t :: %__MODULE__{
          fee: String.t(),
          is_sanctioned: boolean(),
          user_exists: boolean(),
          user_has_sent_tx: boolean()
        }

  @primary_key false
  embedded_schema do
    field(:fee, :string)
    field(:is_sanctioned, :boolean)
    field(:user_exists, :boolean)
    field(:user_has_sent_tx, :boolean)
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for pre-transfer check data.

  ## Parameters
    - `check`: The pre-transfer check struct
    - `attrs`: Map of attributes to validate

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(check \\ %__MODULE__{}, attrs) do
    check
    |> cast(attrs, [:fee, :is_sanctioned, :user_exists, :user_has_sent_tx])
    |> validate_required([:fee, :is_sanctioned, :user_exists, :user_has_sent_tx])
  end

  # ===================== Helpers =====================

  @doc """
  Check if user exists.
  """
  @spec user_exists?(t()) :: boolean()
  def user_exists?(%__MODULE__{user_exists: exists}), do: exists == true

  @doc """
  Check if user is sanctioned.
  """
  @spec sanctioned?(t()) :: boolean()
  def sanctioned?(%__MODULE__{is_sanctioned: sanctioned}), do: sanctioned == true

  @doc """
  Get activation fee.
  """
  @spec activation_fee(t()) :: String.t()
  def activation_fee(%__MODULE__{fee: fee}), do: fee
end
