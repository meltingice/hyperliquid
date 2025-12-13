defmodule Hyperliquid.Api.Info.DelegatorHistory do
  @moduledoc """
  History of user's delegation actions.

  Returns delegation and undelegation events with timestamps and transaction hashes.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#retrieve-delegator-history

  ## Usage

      {:ok, history} = DelegatorHistory.request("0x1234...")
      delegations = DelegatorHistory.delegations(history)
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "delegatorHistory",
    params: [:user],
    rate_limit_cost: 2,
    doc: "Retrieve history of user's delegation actions",
    returns: "Delegation and undelegation events with timestamps and transaction hashes"

  @type t :: %__MODULE__{
          events: [Event.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :events, Event, primary_key: false do
      @moduledoc "Delegation event."

      field(:time, :integer)
      field(:hash, :string)

      embeds_one :delta, Delta, primary_key: false do
        @moduledoc "Delegation change details."

        embeds_one :delegate, Delegate, primary_key: false do
          @moduledoc "Delegation action."

          field(:validator, :string)
          field(:amount, :string)
          field(:is_undelegate, :boolean)
        end
      end
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{events: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for delegator history data.

  ## Parameters
    - `history`: The delegator history struct
    - `attrs`: Map with events key

  ## Returns
    - `Ecto.Changeset.t()`
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(history \\ %__MODULE__{}, attrs) do
    history
    |> cast(attrs, [])
    |> cast_embed(:events, with: &event_changeset/2)
  end

  defp event_changeset(event, attrs) do
    event
    |> cast(attrs, [:time, :hash])
    |> cast_embed(:delta, with: &delta_changeset/2)
    |> validate_required([:time, :hash])
  end

  defp delta_changeset(delta, attrs) do
    delta
    |> cast(attrs, [])
    |> cast_embed(:delegate, with: &delegate_changeset/2)
  end

  defp delegate_changeset(delegate, attrs) do
    delegate
    |> cast(attrs, [:validator, :amount, :is_undelegate])
    |> validate_required([:validator, :amount])
  end

  # ===================== Helpers =====================

  @doc """
  Get delegation events only.

  ## Parameters
    - `history`: The delegator history struct

  ## Returns
    - List of delegation events
  """
  @spec delegations(t()) :: [map()]
  def delegations(%__MODULE__{events: events}) do
    Enum.filter(events, fn event ->
      event.delta && event.delta.delegate && event.delta.delegate.is_undelegate == false
    end)
  end

  @doc """
  Get undelegation events only.

  ## Parameters
    - `history`: The delegator history struct

  ## Returns
    - List of undelegation events
  """
  @spec undelegations(t()) :: [map()]
  def undelegations(%__MODULE__{events: events}) do
    Enum.filter(events, fn event ->
      event.delta && event.delta.delegate && event.delta.delegate.is_undelegate == true
    end)
  end

  @doc """
  Get events for a specific validator.

  ## Parameters
    - `history`: The delegator history struct
    - `validator`: Validator address

  ## Returns
    - List of events for the validator
  """
  @spec for_validator(t(), String.t()) :: [map()]
  def for_validator(%__MODULE__{events: events}, validator) when is_binary(validator) do
    validator_lower = String.downcase(validator)

    Enum.filter(events, fn event ->
      event.delta &&
        event.delta.delegate &&
        String.downcase(event.delta.delegate.validator || "") == validator_lower
    end)
  end

  @doc """
  Get events within a time range.

  ## Parameters
    - `history`: The delegator history struct
    - `start_time`: Start timestamp in ms
    - `end_time`: End timestamp in ms

  ## Returns
    - List of events in range
  """
  @spec in_range(t(), non_neg_integer(), non_neg_integer()) :: [map()]
  def in_range(%__MODULE__{events: events}, start_time, end_time) do
    Enum.filter(events, fn event ->
      event.time >= start_time and event.time <= end_time
    end)
  end

  @doc """
  Get the most recent event.

  ## Parameters
    - `history`: The delegator history struct

  ## Returns
    - `{:ok, Event.t()}` if events exist
    - `{:error, :empty}` if no events
  """
  @spec latest(t()) :: {:ok, map()} | {:error, :empty}
  def latest(%__MODULE__{events: []}) do
    {:error, :empty}
  end

  def latest(%__MODULE__{events: events}) do
    {:ok, Enum.max_by(events, & &1.time)}
  end
end
