defmodule Hyperliquid.Application do
  @moduledoc false

  use Application

  alias Hyperliquid.{Cache, Config}

  @cache :hyperliquid

  @impl true
  def start(_type, _args) do
    # Validate DB dependencies if enabled
    if Config.db_enabled?() do
      validate_db_dependencies!()
    end

    # Core children that always start
    core_children = [
      {Phoenix.PubSub, name: Hyperliquid.PubSub},
      {Cachex, name: @cache},
      {Hyperliquid.Rpc.Registry, [rpcs: Config.named_rpcs()]},
      Hyperliquid.WebSocket.Supervisor
    ]

    # Database children (only when enable_db: true)
    db_children =
      if Config.db_enabled?() do
        [Hyperliquid.Repo, Hyperliquid.Storage.Writer]
      else
        []
      end

    # Build final children list
    children = core_children ++ db_children

    # Conditionally add cache initialization task
    children =
      if Config.autostart_cache?() do
        children ++ [{Task, fn -> init_cache() end}]
      else
        children
      end

    opts = [strategy: :one_for_one, name: Hyperliquid.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp validate_db_dependencies! do
    required_apps = [:ecto_sql, :postgrex, :phoenix_ecto]

    missing_apps =
      Enum.reject(required_apps, fn app ->
        case Application.load(app) do
          :ok -> true
          {:error, {:already_loaded, _}} -> true
          _ -> false
        end
      end)

    unless Enum.empty?(missing_apps) do
      raise """
      Database features are enabled (enable_db: true) but required dependencies are missing.

      Missing dependencies: #{inspect(missing_apps)}

      Please add to your mix.exs deps:
        {:phoenix_ecto, "~> 4.5"},
        {:ecto_sql, "~> 3.10"},
        {:postgrex, ">= 0.0.0"}

      Then run: mix deps.get

      Or disable database features in your config:
        config :hyperliquid, enable_db: false
      """
    end
  end

  defp init_cache do
    # Small delay to ensure Cachex is ready
    Process.sleep(100)

    case Cache.init() do
      :ok ->
        :ok

      {:error, reason} ->
        # Log the error but don't crash the application
        require Logger
        Logger.warning("Failed to initialize Hyperliquid cache: #{inspect(reason)}")
        :error
    end
  end
end
