defmodule Hyperliquid.Api.Info do
  @moduledoc """
  Convenience functions for Info API endpoints.

  This module provides snake_case wrapper functions that delegate to the
  underlying endpoint modules, improving developer ergonomics.

  ## Usage

      # Direct endpoint call (still supported)
      {:ok, mids} = Hyperliquid.Api.Info.AllMids.request()

      # Convenience wrapper (new)
      {:ok, mids} = Hyperliquid.Api.Info.all_mids()

      # With parameters
      {:ok, book} = Hyperliquid.Api.Info.l2_book("BTC")
      {:ok, state} = Hyperliquid.Api.Info.clearinghouse_state("0xabc...")

  ## Available Functions

  All Info endpoints are available as snake_case functions. Each endpoint
  provides both safe and bang variants:

  - `endpoint_name(...)` - Returns `{:ok, result}` or `{:error, reason}`
  - `endpoint_name!(...)` - Returns `result` or raises on error

  For endpoints with storage enabled, additional `fetch_*` variants are available:

  - `fetch_endpoint_name(...)` - Request and persist to storage backends

  See `Hyperliquid.Api.Registry.list_by_type(:info)` for all available endpoints.
  """

  alias Hyperliquid.Api.Registry

  # Generate delegated functions for all Info endpoints at compile time
  for endpoint_module <- Registry.list_context_endpoints(:info) do
    # Get endpoint metadata
    Code.ensure_loaded!(endpoint_module)

    if function_exported?(endpoint_module, :__endpoint_info__, 0) do
      info = endpoint_module.__endpoint_info__()
      params = info.params
      optional_params = info.optional_params
      has_storage = function_exported?(endpoint_module, :storage_enabled?, 0) && endpoint_module.storage_enabled?()

      # Convert module name to snake_case function name
      # E.g., AllMids -> all_mids, L2Book -> l2_book
      module_name =
        endpoint_module
        |> Module.split()
        |> List.last()

      function_name =
        module_name
        |> Macro.underscore()
        |> String.to_atom()

      # Generate appropriate function signatures based on parameters
      cond do
        # No parameters - simple endpoint
        Enum.empty?(params) && Enum.empty?(optional_params) ->
          @doc """
          #{info.doc}

          Delegates to `#{inspect(endpoint_module)}.request/0`.

          ## Returns

          #{info.returns}

          ## Examples

              {:ok, result} = #{function_name}()
          """
          @spec unquote(function_name)() :: {:ok, struct()} | {:error, term()}
          def unquote(function_name)() do
            unquote(endpoint_module).request()
          end

          @doc """
          #{info.doc} (bang variant)

          Delegates to `#{inspect(endpoint_module)}.request!/0`.

          Raises on error.
          """
          @spec unquote(:"#{function_name}!")() :: struct()
          def unquote(:"#{function_name}!")() do
            unquote(endpoint_module).request!()
          end

          if has_storage do
            @doc """
            #{info.doc}

            Fetches data and persists to configured storage backends.

            Delegates to `#{inspect(endpoint_module)}.fetch/0`.
            """
            @spec unquote(:"fetch_#{function_name}")() :: {:ok, struct()} | {:error, term()}
            def unquote(:"fetch_#{function_name}")() do
              unquote(endpoint_module).fetch()
            end

            @doc """
            #{info.doc} (fetch bang variant)

            Fetches data, persists to storage, and raises on error.

            Delegates to `#{inspect(endpoint_module)}.fetch!/0`.
            """
            @spec unquote(:"fetch_#{function_name}!")() :: struct()
            def unquote(:"fetch_#{function_name}!")() do
              unquote(endpoint_module).fetch!()
            end
          end

        # Has optional params but no required params
        Enum.empty?(params) && !Enum.empty?(optional_params) ->
          @doc """
          #{info.doc}

          Delegates to `#{inspect(endpoint_module)}.request/1`.

          ## Parameters

          - `opts` - Optional parameters: #{inspect(optional_params)}

          ## Returns

          #{info.returns}
          """
          @spec unquote(function_name)(keyword()) :: {:ok, struct()} | {:error, term()}
          def unquote(function_name)(opts \\ []) do
            unquote(endpoint_module).request(opts)
          end

          @doc """
          #{info.doc} (bang variant)

          Delegates to `#{inspect(endpoint_module)}.request!/1`.

          Raises on error.
          """
          @spec unquote(:"#{function_name}!")(keyword()) :: struct()
          def unquote(:"#{function_name}!")(opts \\ []) do
            unquote(endpoint_module).request!(opts)
          end

          if has_storage do
            @doc """
            #{info.doc}

            Fetches data and persists to configured storage backends.

            Delegates to `#{inspect(endpoint_module)}.fetch/1`.
            """
            @spec unquote(:"fetch_#{function_name}")(keyword()) :: {:ok, struct()} | {:error, term()}
            def unquote(:"fetch_#{function_name}")(opts \\ []) do
              unquote(endpoint_module).fetch(opts)
            end

            @doc """
            #{info.doc} (fetch bang variant)

            Delegates to `#{inspect(endpoint_module)}.fetch!/1`.
            """
            @spec unquote(:"fetch_#{function_name}!")(keyword()) :: struct()
            def unquote(:"fetch_#{function_name}!")(opts \\ []) do
              unquote(endpoint_module).fetch!(opts)
            end
          end

        # Has required params (with or without optional params)
        true ->
          # Build parameter variables for function signature
          param_vars = for param <- params, do: Macro.var(param, nil)

          # Determine if we need opts parameter
          needs_opts = !Enum.empty?(optional_params)

          if needs_opts do
            # Function with required params + opts
            @doc """
            #{info.doc}

            Delegates to `#{inspect(endpoint_module)}.request/#{length(params) + 1}`.

            ## Parameters

            #{Enum.map_join(params, "\n", fn p -> "- `#{p}` - Required parameter" end)}
            - `opts` - Optional parameters: #{inspect(optional_params)}

            ## Returns

            #{info.returns}
            """
            @spec unquote(function_name)(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end)), keyword()) ::
                    {:ok, struct()} | {:error, term()}
            def unquote(function_name)(unquote_splicing(param_vars), opts \\ []) do
              unquote(endpoint_module).request(unquote_splicing(param_vars), opts)
            end

            @doc """
            #{info.doc} (bang variant)

            Delegates to `#{inspect(endpoint_module)}.request!/#{length(params) + 1}`.

            Raises on error.
            """
            @spec unquote(:"#{function_name}!")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end)), keyword()) ::
                    struct()
            def unquote(:"#{function_name}!")(unquote_splicing(param_vars), opts \\ []) do
              unquote(endpoint_module).request!(unquote_splicing(param_vars), opts)
            end

            if has_storage do
              @doc """
              #{info.doc}

              Fetches data and persists to configured storage backends.

              Delegates to `#{inspect(endpoint_module)}.fetch/#{length(params) + 1}`.
              """
              @spec unquote(:"fetch_#{function_name}")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end)), keyword()) ::
                      {:ok, struct()} | {:error, term()}
              def unquote(:"fetch_#{function_name}")(unquote_splicing(param_vars), opts \\ []) do
                unquote(endpoint_module).fetch(unquote_splicing(param_vars), opts)
              end

              @doc """
              #{info.doc} (fetch bang variant)

              Delegates to `#{inspect(endpoint_module)}.fetch!/#{length(params) + 1}`.
              """
              @spec unquote(:"fetch_#{function_name}!")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end)), keyword()) ::
                      struct()
              def unquote(:"fetch_#{function_name}!")(unquote_splicing(param_vars), opts \\ []) do
                unquote(endpoint_module).fetch!(unquote_splicing(param_vars), opts)
              end
            end
          else
            # Function with only required params (no opts)
            @doc """
            #{info.doc}

            Delegates to `#{inspect(endpoint_module)}.request/#{length(params)}`.

            ## Parameters

            #{Enum.map_join(params, "\n", fn p -> "- `#{p}` - Required parameter" end)}

            ## Returns

            #{info.returns}
            """
            @spec unquote(function_name)(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end))) ::
                    {:ok, struct()} | {:error, term()}
            def unquote(function_name)(unquote_splicing(param_vars)) do
              unquote(endpoint_module).request(unquote_splicing(param_vars))
            end

            @doc """
            #{info.doc} (bang variant)

            Delegates to `#{inspect(endpoint_module)}.request!/#{length(params)}`.

            Raises on error.
            """
            @spec unquote(:"#{function_name}!")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end))) ::
                    struct()
            def unquote(:"#{function_name}!")(unquote_splicing(param_vars)) do
              unquote(endpoint_module).request!(unquote_splicing(param_vars))
            end

            if has_storage do
              @doc """
              #{info.doc}

              Fetches data and persists to configured storage backends.

              Delegates to `#{inspect(endpoint_module)}.fetch/#{length(params)}`.
              """
              @spec unquote(:"fetch_#{function_name}")(unquote_splicing(Enum.map(params, fn _ -> quote do: term() end))) ::
                      {:ok, struct()} | {:error, term()}
              def unquote(:"fetch_#{function_name}")(unquote_splicing(param_vars)) do
                unquote(endpoint_module).fetch(unquote_splicing(param_vars))
              end

              @doc """
              #{info.doc} (fetch bang variant)

              Delegates to `#{inspect(endpoint_module)}.fetch!/#{length(params)}`.
              """
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
