defmodule Hyperliquid.Api.Info.UserRateLimit do
  @moduledoc """
  User's rate limit status.

  Returns current rate limit usage and limits.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint#query-user-rate-limits

  ## Usage

      {:ok, limit} = UserRateLimit.request("0x...")
      IO.puts("Used: \#{UserRateLimit.usage_percent(limit)}%")
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "userRateLimit",
    params: [:user],
    rate_limit_cost: 20,
    doc: "Query user rate limit status",
    returns: "UserRateLimit with usage and cap"

  @type t :: %__MODULE__{
          cum_vlm: String.t(),
          n_requests_used: non_neg_integer(),
          n_requests_cap: non_neg_integer(),
          n_requests_surplus: non_neg_integer()
        }

  @primary_key false
  embedded_schema do
    field(:cum_vlm, :string)
    field(:n_requests_used, :integer)
    field(:n_requests_cap, :integer)
    field(:n_requests_surplus, :integer)
  end

  # ===================== Changeset =====================

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(limit \\ %__MODULE__{}, attrs) do
    limit
    |> cast(attrs, [:cum_vlm, :n_requests_used, :n_requests_cap, :n_requests_surplus])
    |> validate_required([:cum_vlm, :n_requests_used, :n_requests_cap, :n_requests_surplus])
  end

  # ===================== Helpers =====================

  @spec usage_percent(t()) :: float()
  def usage_percent(%__MODULE__{n_requests_used: used, n_requests_cap: cap}) when cap > 0 do
    used / cap * 100
  end

  def usage_percent(_), do: 0.0

  @spec remaining(t()) :: non_neg_integer()
  def remaining(%__MODULE__{n_requests_used: used, n_requests_cap: cap}) do
    max(0, cap - used)
  end
end
