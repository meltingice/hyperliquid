defmodule Hyperliquid.Api.Info.UserDexAbstraction do
  @moduledoc """
  User DEX abstraction settings.

  Returns DEX abstraction configuration for a user.

  See: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
  """

  use Hyperliquid.Api.Endpoint,
    type: :info,
    request_type: "userDexAbstraction",
    params: [:user],
    rate_limit_cost: 1,
    doc: "Retrieve user DEX abstraction settings",
    returns: "DEX abstraction configuration for a user"

  @type t :: %__MODULE__{
          enabled: boolean() | nil
        }

  @primary_key false
  embedded_schema do
    field(:enabled, :boolean)
  end

  # ===================== Preprocessing =====================

  @doc false
  # API returns boolean | null directly
  def preprocess(data) when is_boolean(data) do
    %{enabled: data}
  end

  def preprocess(nil) do
    %{enabled: nil}
  end

  def preprocess(data) when is_map(data), do: data

  # ===================== Changesets =====================

  @doc """
  Creates a changeset for user DEX abstraction data.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(abstraction \\ %__MODULE__{}, attrs) do
    abstraction
    |> cast(attrs, [:enabled])
  end

  # ===================== Helpers =====================

  @doc """
  Check if DEX abstraction is enabled.
  """
  @spec enabled?(t()) :: boolean()
  def enabled?(%__MODULE__{enabled: enabled}), do: enabled == true
end
