defmodule Hyperliquid.Api.Info.VaultSummaries do
  @moduledoc """
  Vault summaries.

  Returns summary information for vaults.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint

  ## Usage

      {:ok, summaries} = VaultSummaries.request()
      {:ok, vault} = VaultSummaries.find_by_address(summaries, "0x...")
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "vaultSummaries",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve vault summaries",
    returns: "Summary information for all vaults"

  @type t :: %__MODULE__{
          vaults: [Vault.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :vaults, Vault, primary_key: false do
      field(:name, :string)
      field(:vault_address, :string)
      field(:leader, :string)
      field(:tvl, :string)
      field(:is_closed, :boolean)
      field(:relationship, :map)
      field(:create_time_millis, :integer)
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
  Creates a changeset for vault summaries data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(summaries \\ %__MODULE__{}, attrs) do
    summaries
    |> cast(attrs, [])
    |> cast_embed(:vaults, with: &vault_changeset/2)
  end

  defp vault_changeset(vault, attrs) do
    vault
    |> cast(attrs, [
      :name,
      :vault_address,
      :leader,
      :tvl,
      :is_closed,
      :relationship,
      :create_time_millis
    ])
    |> validate_required([:name, :vault_address, :leader, :tvl])
  end

  # ===================== Helpers =====================

  @doc """
  Finds a vault by its address.

  ## Parameters
    - `summaries`: The vault summaries struct
    - `addr`: Vault address to search for

  ## Returns
    - `{:ok, vault}` if found
    - `{:error, :not_found}` if not found
  """
  @spec find_by_address(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def find_by_address(%__MODULE__{vaults: vaults}, addr) do
    addr_lower = String.downcase(addr)

    case Enum.find(vaults, &(String.downcase(&1.vault_address) == addr_lower)) do
      nil -> {:error, :not_found}
      vault -> {:ok, vault}
    end
  end

  @doc """
  Returns the number of vaults.
  """
  @spec count(t()) :: non_neg_integer()
  def count(%__MODULE__{vaults: vaults}), do: length(vaults)

  @doc """
  Calculates total TVL across all vaults.

  ## Returns
    - `{:ok, float()}` - Total TVL
    - `{:error, :parse_error}` - If TVL values can't be parsed
  """
  @spec total_tvl(t()) :: {:ok, float()} | {:error, :parse_error}
  def total_tvl(%__MODULE__{vaults: vaults}) do
    try do
      total = vaults |> Enum.map(&String.to_float(&1.tvl)) |> Enum.sum()
      {:ok, total}
    rescue
      _ -> {:error, :parse_error}
    end
  end
end
