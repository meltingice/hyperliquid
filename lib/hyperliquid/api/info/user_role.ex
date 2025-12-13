defmodule Hyperliquid.Api.Info.UserRole do
  @moduledoc """
  User's role information.

  Returns the user's role and permissions.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "userRole",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Retrieve user role information",
    returns: "User's role and permissions"

  @type t :: %__MODULE__{
          role: String.t(),
          permissions: [String.t()]
        }

  @primary_key false
  embedded_schema do
    field(:role, :string)
    field(:permissions, {:array, :string})
  end

  # ===================== Changesets =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(role \\ %__MODULE__{}, attrs) do
    role
    |> cast(attrs, [:role, :permissions])
    |> validate_required([:role])
  end

  # ===================== Helpers =====================

  @spec has_permission?(t(), String.t()) :: boolean()
  def has_permission?(%__MODULE__{permissions: perms}, perm) when is_list(perms) do
    perm in perms
  end

  def has_permission?(_, _), do: false
end
