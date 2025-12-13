defmodule Hyperliquid.Api.Info.ExtraAgents do
  @moduledoc """
  Extra agents authorized by a user.

  Returns list of additional agents (sub-accounts or authorized traders) for a user.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint

  ## Usage

      {:ok, agents} = ExtraAgents.request("0x1234...")
      ExtraAgents.authorized?(agents, "0x5678...")
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "extraAgents",
    params: [:user],
    rate_limit_cost: 2,
    doc: "Retrieve extra agents authorized by a user",
    returns: "List of additional agents with addresses, names, and validity periods"

  @type t :: %__MODULE__{
          agents: [Agent.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :agents, Agent, primary_key: false do
      @moduledoc "Extra agent information."

      field(:address, :string)
      field(:name, :string)
      field(:valid_until, :integer)
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{agents: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for extra agents data.

  ## Parameters
    - `agents`: The extra agents struct
    - `attrs`: Map with agents key

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(agents \\ %__MODULE__{}, attrs) do
    agents
    |> cast(attrs, [])
    |> cast_embed(:agents, with: &agent_changeset/2)
  end

  defp agent_changeset(agent, attrs) do
    agent
    |> cast(attrs, [:address, :name, :valid_until])
    |> validate_required([:address])
  end

  # ===================== Helpers =====================

  @doc """
  Get count of extra agents.

  ## Parameters
    - `agents`: The extra agents struct

  ## Returns
    - `non_neg_integer()`
  """
  @spec count(t()) :: non_neg_integer()
  def count(%__MODULE__{agents: agents}) do
    length(agents)
  end

  @doc """
  Check if an address is an authorized agent.

  ## Parameters
    - `agents`: The extra agents struct
    - `address`: Address to check

  ## Returns
    - `boolean()`
  """
  @spec authorized?(t(), String.t()) :: boolean()
  def authorized?(%__MODULE__{agents: agents}, address) when is_binary(address) do
    address_lower = String.downcase(address)
    Enum.any?(agents, &(String.downcase(&1.address) == address_lower))
  end

  @doc """
  Find agent by address.

  ## Parameters
    - `agents`: The extra agents struct
    - `address`: Agent address

  ## Returns
    - `{:ok, Agent.t()}` if found
    - `{:error, :not_found}` if not found
  """
  @spec find_by_address(t(), String.t()) :: {:ok, map()} | {:error, :not_found}
  def find_by_address(%__MODULE__{agents: agents}, address) when is_binary(address) do
    address_lower = String.downcase(address)

    case Enum.find(agents, &(String.downcase(&1.address) == address_lower)) do
      nil -> {:error, :not_found}
      agent -> {:ok, agent}
    end
  end

  @doc """
  Get all agent addresses.

  ## Parameters
    - `agents`: The extra agents struct

  ## Returns
    - List of agent addresses
  """
  @spec addresses(t()) :: [String.t()]
  def addresses(%__MODULE__{agents: agents}) do
    Enum.map(agents, & &1.address)
  end

  @doc """
  Get agents that are still valid.

  ## Parameters
    - `agents`: The extra agents struct
    - `current_time`: Current time in milliseconds

  ## Returns
    - List of valid agents
  """
  @spec valid_agents(t(), non_neg_integer()) :: [map()]
  def valid_agents(%__MODULE__{agents: agents}, current_time) when is_integer(current_time) do
    Enum.filter(agents, fn agent ->
      is_nil(agent.valid_until) || agent.valid_until > current_time
    end)
  end
end
