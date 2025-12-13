defmodule Hyperliquid.Api.Info.UserNonFundingLedgerUpdates do
  @moduledoc """
  User's non-funding ledger updates.

  Returns deposits, withdrawals, transfers, and other non-funding ledger entries.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "userNonFundingLedgerUpdates",
    params: [:user, :start_time],
    rate_limit_cost: 1,
    doc: "Retrieve user's non-funding ledger updates",
    returns: "Deposits, withdrawals, transfers, and other non-funding ledger entries"

  alias Hyperliquid.Transport.Http

  @type t :: %__MODULE__{
          updates: [Update.t()]
        }

  @primary_key false
  embedded_schema do
    embeds_many :updates, Update, primary_key: false do
      field(:time, :integer)
      field(:hash, :string)
      field(:delta, :map)
    end
  end

  # ===================== Custom Request Methods =====================

  @doc """
  Build the request payload with optional end_time parameter.

  ## Parameters
    - `user`: User address (0x...)
    - `start_time`: Start timestamp in ms
    - `end_time`: Optional end timestamp in ms

  ## Returns
    - Map with request parameters
  """
  @spec build_request_with_end_time(String.t(), non_neg_integer(), non_neg_integer()) :: map()
  def build_request_with_end_time(user, start_time, end_time)
      when is_binary(user) and is_integer(end_time) do
    %{
      type: "userNonFundingLedgerUpdates",
      user: user,
      startTime: start_time,
      endTime: end_time
    }
  end

  @doc """
  Fetches ledger updates with optional end_time parameter.

  ## Parameters
    - `user`: User address (0x...)
    - `start_time`: Start timestamp in ms
    - `end_time`: Optional end timestamp in ms

  ## Returns
    - `{:ok, %UserNonFundingLedgerUpdates{}}` - Parsed and validated data
    - `{:error, term()}` - Error from HTTP or validation
  """
  @spec request_with_end_time(String.t(), non_neg_integer(), non_neg_integer() | nil) ::
          {:ok, t()} | {:error, term()}
  def request_with_end_time(user, start_time, end_time) when is_integer(end_time) do
    with {:ok, data} <-
           Http.info_request(build_request_with_end_time(user, start_time, end_time)),
         {:ok, result} <- parse_response(data) do
      {:ok, result}
    end
  end

  # ===================== Preprocessing =====================

  @doc false
  def preprocess(data) when is_list(data) do
    %{updates: data}
  end

  def preprocess(data), do: data

  # ===================== Changesets =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(updates \\ %__MODULE__{}, attrs) do
    updates
    |> cast(attrs, [])
    |> cast_embed(:updates, with: &update_changeset/2)
  end

  defp update_changeset(update, attrs) do
    attrs = normalize_attrs(attrs)

    update
    |> cast(attrs, [:time, :hash, :delta])
    |> validate_required([:time, :hash])
  end

  defp normalize_attrs(attrs) do
    %{
      time: attrs["time"] || attrs[:time],
      hash: attrs["hash"] || attrs[:hash],
      delta: attrs["delta"] || attrs[:delta]
    }
  end

  # ===================== Helpers =====================

  @spec count(t()) :: non_neg_integer()
  def count(%__MODULE__{updates: updates}), do: length(updates)
end
