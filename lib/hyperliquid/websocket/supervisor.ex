defmodule Hyperliquid.WebSocket.Supervisor do
  @moduledoc """
  Supervisor for the WebSocket subsystem.

  Supervises:
  - Registry for connection lookups
  - DynamicSupervisor for connection processes
  - Manager for orchestration

  ## Usage

  Add to your application supervision tree:

      children = [
        Hyperliquid.WebSocket.Supervisor,
        # ... other children
      ]

      Supervisor.start_link(children, strategy: :one_for_one)
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Registry for looking up connections by key
      {Registry, keys: :unique, name: Hyperliquid.WebSocket.Registry},

      # DynamicSupervisor for spawning connection processes
      {DynamicSupervisor,
       name: Hyperliquid.WebSocket.ConnectionSupervisor, strategy: :one_for_one},

      # Manager for orchestration
      {Hyperliquid.WebSocket.Manager, name: Hyperliquid.WebSocket.Manager}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
