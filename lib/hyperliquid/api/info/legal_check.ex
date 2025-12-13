defmodule Hyperliquid.Api.Info.LegalCheck do
  @moduledoc """
  Legal/compliance check for a user.

  Returns whether a user is allowed to use the platform based on jurisdiction.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "legalCheck",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Check legal/compliance status for a user",
    returns: "Whether user is allowed to use the platform based on jurisdiction"

  @type t :: %__MODULE__{
          ip_allowed: boolean(),
          accepted_terms: boolean(),
          user_allowed: boolean()
        }

  @primary_key false
  embedded_schema do
    field(:ip_allowed, :boolean)
    field(:accepted_terms, :boolean)
    field(:user_allowed, :boolean)
  end

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for legal check data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(check \\ %__MODULE__{}, attrs) do
    check
    |> cast(attrs, [:ip_allowed, :accepted_terms, :user_allowed])
    |> validate_required([:ip_allowed, :accepted_terms, :user_allowed])
  end

  @doc """
  Check if user is fully allowed (IP, terms, and user all allowed).
  """
  @spec allowed?(t()) :: boolean()
  def allowed?(%__MODULE__{ip_allowed: ip, accepted_terms: terms, user_allowed: user}) do
    ip == true and terms == true and user == true
  end

  @doc """
  Check if IP is allowed.
  """
  @spec ip_allowed?(t()) :: boolean()
  def ip_allowed?(%__MODULE__{ip_allowed: allowed}), do: allowed == true
end
