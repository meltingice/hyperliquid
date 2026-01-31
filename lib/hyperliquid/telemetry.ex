defmodule Hyperliquid.Telemetry do
  @moduledoc """
  Telemetry events emitted by Hyperliquid.

  ## API Events

  These events are emitted by the endpoint DSL for all Info and Exchange API calls:

  * `[:hyperliquid, :api, :request, :start]` — Info API request started
    * Measurements: `%{system_time: integer}`
    * Metadata: `%{module: module, request_type: String.t()}`

  * `[:hyperliquid, :api, :request, :stop]` — Info API request completed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{module: module, request_type: String.t(), result: :ok}`

  * `[:hyperliquid, :api, :request, :exception]` — Info API request failed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{module: module, request_type: String.t(), result: :error, reason: term}`

  * `[:hyperliquid, :api, :exchange, :start]` — Exchange API request started
    * Measurements: `%{system_time: integer}`
    * Metadata: `%{module: module, action_type: String.t()}`

  * `[:hyperliquid, :api, :exchange, :stop]` — Exchange API request completed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{module: module, action_type: String.t(), result: :ok}`

  * `[:hyperliquid, :api, :exchange, :exception]` — Exchange API request failed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{module: module, action_type: String.t(), result: :error, reason: term}`

  ## WebSocket Events

  * `[:hyperliquid, :ws, :connect, :start]` — Connection attempt started
    * Measurements: `%{system_time: integer}`
    * Metadata: `%{key: String.t()}`

  * `[:hyperliquid, :ws, :connect, :stop]` — Connection established
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{key: String.t()}`

  * `[:hyperliquid, :ws, :connect, :exception]` — Connection failed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{key: String.t(), reason: term}`

  * `[:hyperliquid, :ws, :message, :received]` — Message received
    * Measurements: `%{count: 1}`
    * Metadata: `%{key: String.t()}`

  * `[:hyperliquid, :ws, :disconnect]` — Connection lost
    * Measurements: `%{}`
    * Metadata: `%{key: String.t(), reason: term}`

  ## WebSocket Manager Events

  * `[:hyperliquid, :ws, :subscribe]` — Subscription created
    * Measurements: `%{count: 1}`
    * Metadata: `%{module: module, key: String.t()}`

  * `[:hyperliquid, :ws, :unsubscribe]` — Subscription removed
    * Measurements: `%{count: 1}`
    * Metadata: `%{subscription_id: String.t()}`

  ## Cache Events

  * `[:hyperliquid, :cache, :init, :stop]` — Cache initialization completed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{}`

  * `[:hyperliquid, :cache, :init, :exception]` — Cache initialization failed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{reason: term}`

  * `[:hyperliquid, :cache, :refresh, :stop]` — Cache refresh completed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{}`

  ## RPC Events

  * `[:hyperliquid, :rpc, :request, :start]` — RPC request started
    * Measurements: `%{system_time: integer}`
    * Metadata: `%{method: String.t()}`

  * `[:hyperliquid, :rpc, :request, :stop]` — RPC request completed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{method: String.t()}`

  * `[:hyperliquid, :rpc, :request, :exception]` — RPC request failed
    * Measurements: `%{duration: native_time}`
    * Metadata: `%{method: String.t(), reason: term}`

  ## Storage Events

  * `[:hyperliquid, :storage, :flush, :stop]` — Buffer flushed
    * Measurements: `%{record_count: integer, duration: native_time}`
    * Metadata: `%{}`

  ## Quick Setup

      Hyperliquid.Telemetry.attach_default_logger()

  ## Telemetry.Metrics Example

      defmodule MyApp.Telemetry do
        import Telemetry.Metrics

        def metrics do
          [
            summary("hyperliquid.api.request.stop.duration", unit: {:native, :millisecond}),
            summary("hyperliquid.api.exchange.stop.duration", unit: {:native, :millisecond}),
            counter("hyperliquid.ws.message.received.count"),
            summary("hyperliquid.rpc.request.stop.duration", unit: {:native, :millisecond}),
            last_value("hyperliquid.storage.flush.stop.record_count")
          ]
        end
      end
  """

  require Logger

  @doc """
  Attach a default logger that logs all Hyperliquid telemetry events at debug level.

  Useful for quick debugging. Returns `:ok`.
  """
  @spec attach_default_logger() :: :ok
  def attach_default_logger do
    events = [
      [:hyperliquid, :api, :request, :start],
      [:hyperliquid, :api, :request, :stop],
      [:hyperliquid, :api, :request, :exception],
      [:hyperliquid, :api, :exchange, :start],
      [:hyperliquid, :api, :exchange, :stop],
      [:hyperliquid, :api, :exchange, :exception],
      [:hyperliquid, :ws, :connect, :start],
      [:hyperliquid, :ws, :connect, :stop],
      [:hyperliquid, :ws, :connect, :exception],
      [:hyperliquid, :ws, :message, :received],
      [:hyperliquid, :ws, :disconnect],
      [:hyperliquid, :ws, :subscribe],
      [:hyperliquid, :ws, :unsubscribe],
      [:hyperliquid, :cache, :init, :stop],
      [:hyperliquid, :cache, :init, :exception],
      [:hyperliquid, :cache, :refresh, :stop],
      [:hyperliquid, :rpc, :request, :start],
      [:hyperliquid, :rpc, :request, :stop],
      [:hyperliquid, :rpc, :request, :exception],
      [:hyperliquid, :storage, :flush, :stop]
    ]

    :telemetry.attach_many(
      "hyperliquid-default-logger",
      events,
      &__MODULE__.handle_event/4,
      :ok
    )

    :ok
  end

  @doc false
  def handle_event(event, measurements, metadata, _config) do
    Logger.debug(
      "[Hyperliquid.Telemetry] #{inspect(event)} #{inspect(measurements)} #{inspect(metadata)}"
    )
  end
end
