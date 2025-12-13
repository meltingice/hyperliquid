defmodule Hyperliquid.Api.Info.LeadingVaults do
  @moduledoc """
  Leading vaults information.

  Returns top performing vaults with their details.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint

  ## Usage

      {:ok, vaults} = LeadingVaults.request("0xdfc24b077bc1425ad1dea75bcb6f8158e10df303")
      {:ok, vault} = LeadingVaults.find_by_address(vaults, "0x...")
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "leadingVaults",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Retrieve leading vaults information",
    returns: "Top performing vaults with their details"

  @type t :: %__MODULE__{
          vaults: [Vault.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :vaults, Vault, primary_key: false do
      @moduledoc "Vault that a user is leading."

      field(:address, :string)
      field(:name, :string)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{vaults: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for leading vaults data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(vaults \\ %__MODULE__{}, attrs) do
    vaults
    |> cast(attrs, [])
    |> cast_embed(:vaults, with: &vault_changeset/2)
  end

  defp vault_changeset(vault, attrs) do
    vault
    |> cast(attrs, [:address, :name])
    |> validate_required([:address, :name])
  end

  # ===================== Helpers =====================

  @doc """
  Find vault by address.
  """
  @spec find_by_address(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def find_by_address(%__MODULE__{vaults: vaults}, address) do
    addr_lower = String.downcase(address)

    case Enum.find(vaults, &(String.downcase(&1.address) == addr_lower)) do
      nil -> {:error, :not_found}
      vault -> {:ok, vault}
    end
  end

  @doc """
  Get vault count.
  """
  @spec count(t()) :: non_neg_integer()
  def count(%__MODULE__{vaults: vaults}), do: length(vaults)
end
