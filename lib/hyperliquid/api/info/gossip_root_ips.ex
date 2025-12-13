defmodule Hyperliquid.Api.Info.GossipRootIps do
  @moduledoc """
  Gossip network root IP addresses.

  Returns the list of root node IP addresses for the Hyperliquid gossip network.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "gossipRootIps",
    params: [],
    rate_limit_cost: 1,
    doc: "Retrieve gossip network root IP addresses",
    returns: "List of root node IP addresses for the Hyperliquid gossip network"

  @type t :: %__MODULE__{
          ips: [String.t()]
        }

  @primary_key false
  embedded_schema do
    field(:ips, {:array, :string})
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{ips: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for gossip root IPs data.

  ## Parameters
    - `gossip`: The gossip root IPs struct
    - `attrs`: Map with ips key

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(gossip \\ %__MODULE__{}, attrs) do
    gossip
    |> cast(attrs, [:ips])
    |> validate_required([:ips])
    |> validate_ips()
  end

  defp validate_ips(changeset) do
    validate_change(changeset, :ips, fn :ips, ips ->
      if Enum.all?(ips, &is_binary/1) do
        []
      else
        [ips: "all values must be strings"]
      end
    end)
  end

  @doc """
  Get the count of root IPs.

  ## Parameters
    - `gossip`: The gossip root IPs struct

  ## Returns
    - `non_neg_integer()`
  """
  @spec count(t()) :: non_neg_integer()
  def count(%__MODULE__{ips: ips}) do
    length(ips)
  end

  @doc """
  Check if an IP is in the root list.

  ## Parameters
    - `gossip`: The gossip root IPs struct
    - `ip`: IP address to check

  ## Returns
    - `boolean()`
  """
  @spec contains?(t(), String.t()) :: boolean()
  def contains?(%__MODULE__{ips: ips}, ip) when is_binary(ip) do
    ip in ips
  end

  @doc """
  Get a random root IP for connection.

  ## Parameters
    - `gossip`: The gossip root IPs struct

  ## Returns
    - `{:ok, String.t()}` - Random IP
    - `{:error, :empty}` - No IPs available
  """
  @spec random(t()) :: {:ok, String.t()} | {:error, :empty}
  def random(%__MODULE__{ips: []}) do
    {:error, :empty}
  end

  def random(%__MODULE__{ips: ips}) do
    {:ok, Enum.random(ips)}
  end

  @doc """
  Convert IPs to a list.

  ## Parameters
    - `gossip`: The gossip root IPs struct

  ## Returns
    - List of IP strings
  """
  @spec to_list(t()) :: [String.t()]
  def to_list(%__MODULE__{ips: ips}) do
    ips
  end
end
