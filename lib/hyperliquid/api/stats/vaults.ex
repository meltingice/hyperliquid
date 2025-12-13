defmodule Hyperliquid.Api.Stats.Vaults do
  @moduledoc """
  Vaults data from the Hyperliquid stats API.

  Returns vault performance metrics, APR, PnL history, and summary information.

  See: https://stats-data.hyperliquid.xyz/Mainnet/vaults

  ## Usage

      {:ok, vaults} = Vaults.request()
      {:ok, vault} = Vaults.get_vault(vaults, "0x...")
  """

  use Hyperliquid.Api.Endpoint,
    type: :stats,
    request_type: "vaults",
    rate_limit_cost: 0,
    doc: "Retrieve vault performance data",
    returns: "List of vaults with APR, PnL, and summary information",
    storage: [
      cache: [
        enabled: true,
        ttl: :timer.minutes(15),
        key_pattern: "stats:vaults"
      ]
    ]

  @type vault_relationship :: %{
          type: String.t()
        }

  @type vault_summary :: %{
          name: String.t(),
          vault_address: String.t(),
          leader: String.t(),
          tvl: String.t(),
          is_closed: boolean(),
          relationship: vault_relationship(),
          create_time_millis: non_neg_integer()
        }

  @type vault :: %{
          apr: float(),
          pnls: [{String.t(), [String.t()]}],
          summary: vault_summary()
        }

  @type t :: %__MODULE__{
          vaults: [vault()]
        }

  @primary_key false
  embedded_schema do
    field(:vaults, {:array, :map})
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data), do: %{"vaults" => data}
  def preprocess(data), do: data

  # ===================== Cache Extraction =====================

  @doc """
  Extract just the vaults list for cache storage.
  """
  def extract_cache_fields(%{vaults: vaults}), do: vaults
  def extract_cache_fields(%{"vaults" => vaults}), do: vaults
  def extract_cache_fields(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for vaults data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(vaults \\ %__MODULE__{}, attrs) do
    vaults
    |> cast(attrs, [:vaults])
    |> validate_required([:vaults])
  end

  @doc """
  Get the number of vaults.

  ## Parameters
    - `vaults`: The vaults struct

  ## Returns
    - `non_neg_integer()`
  """
  @spec vault_count(t()) :: non_neg_integer()
  def vault_count(%__MODULE__{vaults: vaults}) when is_list(vaults) do
    length(vaults)
  end

  def vault_count(_), do: 0

  @doc """
  Get a specific vault by address.

  ## Parameters
    - `vaults`: The vaults struct
    - `address`: Vault address (0x...)

  ## Returns
    - `{:ok, vault()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec get_vault(t(), String.t()) :: {:ok, vault()} | {:error, :not_found}
  def get_vault(%__MODULE__{vaults: vaults}, address) when is_list(vaults) do
    normalized_address = String.downcase(address)

    case Enum.find(vaults, fn vault ->
           summary = Map.get(vault, "summary", %{})
           vault_address = Map.get(summary, "vault_address", "")
           String.downcase(vault_address) == normalized_address
         end) do
      nil -> {:error, :not_found}
      vault -> {:ok, vault}
    end
  end

  def get_vault(_, _), do: {:error, :not_found}

  @doc """
  Get vaults sorted by APR (descending).

  ## Parameters
    - `vaults`: The vaults struct

  ## Returns
    - `[vault()]`
  """
  @spec by_apr(t()) :: [vault()]
  def by_apr(%__MODULE__{vaults: vaults}) when is_list(vaults) do
    Enum.sort_by(vaults, fn vault -> Map.get(vault, "apr", 0.0) end, :desc)
  end

  def by_apr(_), do: []

  @doc """
  Get vaults sorted by TVL (descending).

  ## Parameters
    - `vaults`: The vaults struct

  ## Returns
    - `[vault()]`
  """
  @spec by_tvl(t()) :: [vault()]
  def by_tvl(%__MODULE__{vaults: vaults}) when is_list(vaults) do
    Enum.sort_by(
      vaults,
      fn vault ->
        summary = Map.get(vault, "summary", %{})
        tvl_str = Map.get(summary, "tvl", "0")

        case Float.parse(tvl_str) do
          {tvl, _} -> tvl
          :error -> 0.0
        end
      end,
      :desc
    )
  end

  def by_tvl(_), do: []

  @doc """
  Filter vaults by open/closed status.

  ## Parameters
    - `vaults`: The vaults struct
    - `is_closed`: true for closed vaults, false for open vaults

  ## Returns
    - `[vault()]`
  """
  @spec filter_by_status(t(), boolean()) :: [vault()]
  def filter_by_status(%__MODULE__{vaults: vaults}, is_closed) when is_list(vaults) do
    Enum.filter(vaults, fn vault ->
      summary = Map.get(vault, "summary", %{})
      Map.get(summary, "is_closed", false) == is_closed
    end)
  end

  def filter_by_status(_, _), do: []

  @doc """
  Get PnL for a specific time window from a vault.

  ## Parameters
    - `vault`: A vault map
    - `window`: Time window ("day", "week", "month", "allTime")

  ## Returns
    - `{:ok, [String.t()]}` if found (list of PnL values)
    - `{:error, :not_found}` if window not found
  """
  @spec get_window_pnl(vault(), String.t()) :: {:ok, [String.t()]} | {:error, :not_found}
  def get_window_pnl(vault, window) when is_map(vault) do
    pnls = Map.get(vault, "pnls", [])

    case Enum.find(pnls, fn [w, _pnl] -> w == window end) do
      nil -> {:error, :not_found}
      [_window, pnl_values] -> {:ok, pnl_values}
    end
  end

  def get_window_pnl(_, _), do: {:error, :not_found}
end
