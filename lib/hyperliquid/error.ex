defmodule Hyperliquid.Error do
  @moduledoc """
  Shared exception for both REST API and JSON-RPC errors.

  Handles:
  - JSON-RPC errors (code/message/data)
  - HTTP errors (status_code/message)
  - Transport errors (reason)
  """
  defexception [:message, :code, :data, :status_code, :reason, :response, :type]

  @impl true
  def exception(err) when is_map(err) do
    cond do
      # JSON-RPC error (string or atom keys)
      Map.has_key?(err, "code") or Map.has_key?(err, :code) ->
        code = Map.get(err, "code") || Map.get(err, :code)
        msg = Map.get(err, "message") || Map.get(err, :message) || "JSON-RPC error"
        data = Map.get(err, "data") || Map.get(err, :data)

        %__MODULE__{
          message: "JSON-RPC #{code}: #{msg}",
          code: code,
          data: data,
          type: :jsonrpc,
          response: err
        }

      # HTTP error
      Map.has_key?(err, :status_code) ->
        %__MODULE__{
          message: "HTTP #{err[:status_code]}: #{err[:message]}",
          status_code: err[:status_code],
          type: :http,
          response: err
        }

      # Transport error
      Map.has_key?(err, :reason) ->
        %__MODULE__{
          message: "Transport error: #{inspect(err[:reason])}",
          reason: err[:reason],
          type: :transport,
          response: err
        }

      # Unknown
      true ->
        %__MODULE__{
          message: "Unknown error: #{inspect(err)}",
          type: :unknown,
          response: err
        }
    end
  end

  def exception(other) do
    %__MODULE__{
      message: "Unknown error: #{inspect(other)}",
      type: :unknown,
      response: other
    }
  end
end
