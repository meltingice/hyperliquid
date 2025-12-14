defmodule Hyperliquid.Api.Exchange do
  @moduledoc """
  Convenience functions for Exchange API endpoints.

  This module provides snake_case wrapper functions that delegate to the
  underlying endpoint modules, improving developer ergonomics.

  ## Usage

      # Direct endpoint call (when available)
      {:ok, result} = Hyperliquid.Api.Exchange.SomeEndpoint.request(...)

      # Convenience wrapper (when DSL is used)
      {:ok, result} = Hyperliquid.Api.Exchange.some_endpoint(...)

  ## Note

  Currently, Exchange endpoints use a different implementation pattern and
  are not yet migrated to the DSL. This module is a placeholder for future
  Exchange endpoint migrations.

  For now, use the existing Exchange modules directly:
  - `Hyperliquid.Api.Exchange.Order`
  - `Hyperliquid.Api.Exchange.Cancel`
  - etc.

  See `Hyperliquid.Api.Registry.list_by_type(:exchange)` for available endpoints.
  """

  alias Hyperliquid.Api.Registry

  # Generate delegated functions for all Exchange endpoints at compile time
  # Currently the list is empty, but this will auto-populate as endpoints migrate to DSL
  for endpoint_module <- Registry.list_context_endpoints(:exchange) do
    Code.ensure_loaded!(endpoint_module)

    if function_exported?(endpoint_module, :__endpoint_info__, 0) do
      info = endpoint_module.__endpoint_info__()
      params = info.params
      optional_params = info.optional_params
      has_storage = function_exported?(endpoint_module, :storage_enabled?, 0) && endpoint_module.storage_enabled?()

      module_name =
        endpoint_module
        |> Module.split()
        |> List.last()

      function_name =
        module_name
        |> Macro.underscore()
        |> String.to_atom()

      cond do
        Enum.empty?(params) && Enum.empty?(optional_params) ->
          @doc """
          #{info.doc}

          Delegates to `#{inspect(endpoint_module)}.request/0`.
          """
          @spec unquote(function_name)() :: {:ok, struct()} | {:error, term()}
          def unquote(function_name)() do
            unquote(endpoint_module).request()
          end

          @doc """
          #{info.doc} (bang variant)
          """
          @spec unquote(:"#{function_name}!")() :: struct()
          def unquote(:"#{function_name}!")() do
            unquote(endpoint_module).request!()
          end

          if has_storage do
            @spec unquote(:"fetch_#{function_name}")() :: {:ok, struct()} | {:error, term()}
            def unquote(:"fetch_#{function_name}")() do
              unquote(endpoint_module).fetch()
            end

            @spec unquote(:"fetch_#{function_name}!")() :: struct()
            def unquote(:"fetch_#{function_name}!")() do
              unquote(endpoint_module).fetch!()
            end
          end

        Enum.empty?(params) && !Enum.empty?(optional_params) ->
          @doc """
          #{info.doc}

          Delegates to `#{inspect(endpoint_module)}.request/1`.
          """
          @spec unquote(function_name)(keyword()) :: {:ok, struct()} | {:error, term()}
          def unquote(function_name)(opts \\ []) do
            unquote(endpoint_module).request(opts)
          end

          @doc """
          #{info.doc} (bang variant)
          """
          @spec unquote(:"#{function_name}!")(keyword()) :: struct()
          def unquote(:"#{function_name}!")(opts \\ []) do
            unquote(endpoint_module).request!(opts)
          end

          if has_storage do
            @spec unquote(:"fetch_#{function_name}")(keyword()) :: {:ok, struct()} | {:error, term()}
            def unquote(:"fetch_#{function_name}")(opts \\ []) do
              unquote(endpoint_module).fetch(opts)
            end

            @spec unquote(:"fetch_#{function_name}!")(keyword()) :: struct()
            def unquote(:"fetch_#{function_name}!")(opts \\ []) do
              unquote(endpoint_module).fetch!(opts)
            end
          end

        true ->
          param_vars = for param <- params, do: Macro.var(param, nil)
          needs_opts = !Enum.empty?(optional_params)

          if needs_opts do
            @doc """
            #{info.doc}

            Delegates to `#{inspect(endpoint_module)}.request/#{length(params) + 1}`.
            """
            @spec unquote(function_name)(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end)), keyword()) ::
                    {:ok, struct()} | {:error, term()}
            def unquote(function_name)(unquote_splicing(param_vars), opts \\ []) do
              unquote(endpoint_module).request(unquote_splicing(param_vars), opts)
            end

            @doc """
            #{info.doc} (bang variant)
            """
            @spec unquote(:"#{function_name}!")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end)), keyword()) ::
                    struct()
            def unquote(:"#{function_name}!")(unquote_splicing(param_vars), opts \\ []) do
              unquote(endpoint_module).request!(unquote_splicing(param_vars), opts)
            end

            if has_storage do
              @spec unquote(:"fetch_#{function_name}")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end)), keyword()) ::
                      {:ok, struct()} | {:error, term()}
              def unquote(:"fetch_#{function_name}")(unquote_splicing(param_vars), opts \\ []) do
                unquote(endpoint_module).fetch(unquote_splicing(param_vars), opts)
              end

              @spec unquote(:"fetch_#{function_name}!")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end)), keyword()) ::
                      struct()
              def unquote(:"fetch_#{function_name}!")(unquote_splicing(param_vars), opts \\ []) do
                unquote(endpoint_module).fetch!(unquote_splicing(param_vars), opts)
              end
            end
          else
            @doc """
            #{info.doc}

            Delegates to `#{inspect(endpoint_module)}.request/#{length(params)}`.
            """
            @spec unquote(function_name)(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end))) ::
                    {:ok, struct()} | {:error, term()}
            def unquote(function_name)(unquote_splicing(param_vars)) do
              unquote(endpoint_module).request(unquote_splicing(param_vars))
            end

            @doc """
            #{info.doc} (bang variant)
            """
            @spec unquote(:"#{function_name}!")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end))) ::
                    struct()
            def unquote(:"#{function_name}!")(unquote_splicing(param_vars)) do
              unquote(endpoint_module).request!(unquote_splicing(param_vars))
            end

            if has_storage do
              @spec unquote(:"fetch_#{function_name}")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end))) ::
                      {:ok, struct()} | {:error, term()}
              def unquote(:"fetch_#{function_name}")(unquote_splicing(param_vars)) do
                unquote(endpoint_module).fetch(unquote_splicing(param_vars))
              end

              @spec unquote(:"fetch_#{function_name}!")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end))) ::
                      struct()
              def unquote(:"fetch_#{function_name}!")(unquote_splicing(param_vars)) do
                unquote(endpoint_module).fetch!(unquote_splicing(param_vars))
              end
            end
          end
      end
    end
  end
end
