defmodule Hyperliquid.Cache.Warmer do
  @moduledoc """
  GenServer for async cache initialization with retry logic.

  Uses handle_continue/2 pattern for non-blocking startup - the supervision tree
  completes immediately while cache initialization happens in the background.

  ## Features

  - Non-blocking startup: Application starts immediately regardless of API availability
  - Partial failure handling: Some cache keys may succeed while others fail
  - Automatic retry: Failed initialization retries with configurable backoff
  - Status introspection: Check initialization status via initialized?/0 and status/0

  ## Usage

  The Warmer is started automatically by the supervision tree when autostart_cache is true.
  You can check its status:

      Hyperliquid.Cache.Warmer.initialized?()
      # => true or false

      Hyperliquid.Cache.Warmer.status()
      # => %{initialized: true, retry_count: 0, last_error: nil}
  """

  use GenServer
  require Logger

  alias Hyperliquid.{Cache, Config}

  # ===================== Public API =====================

  @doc """
  Starts the Cache Warmer GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns whether the cache has been successfully initialized.

  ## Example

      Hyperliquid.Cache.Warmer.initialized?()
      # => true
  """
  def initialized? do
    GenServer.call(__MODULE__, :initialized?)
  end

  @doc """
  Returns the full status of the warmer for debugging.

  ## Example

      Hyperliquid.Cache.Warmer.status()
      # => %{initialized: true, retry_count: 0, last_error: nil}
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # ===================== GenServer Callbacks =====================

  @impl true
  def init(_opts) do
    state = %{
      initialized: false,
      retry_count: 0,
      last_error: nil,
      mids_subscription: nil
    }

    # Fast return - cache init happens in handle_continue
    {:ok, state, {:continue, :init_cache}}
  end

  @impl true
  def handle_continue(:init_cache, state) do
    case Cache.init_with_partial_success() do
      :ok ->
        Logger.info("[Cache.Warmer] Cache initialized successfully")
        mids_sub_id = subscribe_to_live_mids()

        {:noreply,
         %{
           state
           | initialized: true,
             retry_count: 0,
             last_error: nil,
             mids_subscription: mids_sub_id
         }}

      {:ok, :partial, failed_keys} ->
        Logger.warning(
          "[Cache.Warmer] Cache partially initialized, failed keys: #{inspect(failed_keys)}"
        )

        mids_sub_id = subscribe_to_live_mids()

        {:noreply,
         %{
           state
           | initialized: true,
             retry_count: 0,
             last_error: {:partial, failed_keys},
             mids_subscription: mids_sub_id
         }}

      {:error, reason} = error ->
        new_retry_count = state.retry_count + 1
        max_retries = Config.cache_max_retries()

        Logger.warning(
          "[Cache.Warmer] Cache initialization failed (attempt #{new_retry_count}/#{max_retries})",
          error: reason
        )

        if new_retry_count < max_retries do
          retry_delay = Config.cache_retry_delay()
          Process.send_after(self(), :retry, retry_delay)
          {:noreply, %{state | retry_count: new_retry_count, last_error: error}}
        else
          Logger.error(
            "[Cache.Warmer] Max retries (#{max_retries}) exceeded, running in degraded mode"
          )

          {:noreply, %{state | retry_count: new_retry_count, last_error: error}}
        end
    end
  end

  @impl true
  def handle_info(:retry, state) do
    {:noreply, state, {:continue, :init_cache}}
  end

  @impl true
  def handle_call(:initialized?, _from, state) do
    {:reply, state.initialized, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  # ===================== Private Helpers =====================

  defp subscribe_to_live_mids do
    case Cache.subscribe_to_mids() do
      {:ok, sub_id} ->
        Logger.info("[Cache.Warmer] Subscribed to live mid price updates")
        sub_id

      {:error, reason} ->
        Logger.warning("[Cache.Warmer] Failed to subscribe to live mids", error: inspect(reason))
        nil
    end
  end
end
