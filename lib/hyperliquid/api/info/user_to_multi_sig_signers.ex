defmodule Hyperliquid.Api.Info.UserToMultiSigSigners do
  @moduledoc """
  Multi-sig signers for a user.

  Returns list of signers for multi-sig wallets associated with a user.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "userToMultiSigSigners",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Retrieve multi-sig signers for a user",
    returns: "List of signers for multi-sig wallets"

  @type t :: %__MODULE__{
          authorized_users: [String.t()],
          threshold: non_neg_integer() | nil
        }

  @primary_key false
  embedded_schema do
    field(:authorized_users, {:array, :string})
    field(:threshold, :integer)
  end

  # ===================== Preprocessing =====================

  @doc false
  # Response is {authorizedUsers, threshold} | null
  def preprocess(nil), do: %{}

  def preprocess(data) when is_map(data), do: data

  # ===================== Changesets =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(multi_sig \\ %__MODULE__{}, attrs) do
    multi_sig |> cast(attrs, [:authorized_users, :threshold])
  end

  # ===================== Helpers =====================

  @spec signer_count(t()) :: non_neg_integer()
  def signer_count(%__MODULE__{authorized_users: users}) when is_list(users), do: length(users)
  def signer_count(_), do: 0

  @spec is_signer?(t(), String.t()) :: boolean()
  def is_signer?(%__MODULE__{authorized_users: users}, addr) when is_list(users) do
    addr_lower = String.downcase(addr)
    Enum.any?(users, &(String.downcase(&1) == addr_lower))
  end

  def is_signer?(_, _), do: false
end
