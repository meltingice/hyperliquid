defmodule Hyperliquid.Api.Info.UserVaultEquities do
  @moduledoc """
  User's vault equities.

  Returns equity positions in vaults for a user.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-a-users-vault-equities
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "userVaultEquities",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Retrieve user's vault equity positions",
    returns: "Equity positions in vaults for a user"

  @type t :: %__MODULE__{
          equities: [Equity.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :equities, Equity, primary_key: false do
      field(:vault_address, :string)
      field(:equity, :string)
      field(:locked_until_timestamp, :integer)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{equities: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(equities \\ %__MODULE__{}, attrs) do
    equities
    |> cast(attrs, [])
    |> cast_embed(:equities, with: &equity_changeset/2)
  end

  defp equity_changeset(equity, attrs) do
    equity
    |> cast(attrs, [:vault_address, :equity, :locked_until_timestamp])
    |> validate_required([:vault_address, :equity])
  end

  # ===================== Helpers =====================

  @spec total_equity(t()) :: {:ok, float()} | {:error, :parse_error}
  def total_equity(%__MODULE__{equities: equities}) do
    try do
      total = equities |> Enum.map(&String.to_float(&1.equity)) |> Enum.sum()
      {:ok, total}
    rescue
      _ -> {:error, :parse_error}
    end
  end

  @spec find_by_vault(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def find_by_vault(%__MODULE__{equities: equities}, vault) do
    case Enum.find(equities, &(String.downcase(&1.vault_address) == String.downcase(vault))) do
      nil -> {:error, :not_found}
      eq -> {:ok, eq}
    end
  end
end
