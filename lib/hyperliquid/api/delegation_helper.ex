defmodule Hyperliquid.Api.DelegationHelper do
  @moduledoc """
  Helper module for generating delegated wrapper functions for API endpoints.

  This module provides macros to automatically generate snake_case convenience
  functions that delegate to endpoint modules. It eliminates code duplication
  between `Hyperliquid.Api.Info` and `Hyperliquid.Api.Exchange`.

  ## Usage

  In a context module (Info, Exchange, etc.):

      defmodule Hyperliquid.Api.Info do
        require Hyperliquid.Api.DelegationHelper
        alias Hyperliquid.Api.Registry

        DelegationHelper.generate_delegated_functions(:info)
      end

  ## Generated Functions

  For each endpoint module with `__endpoint_info__/0`, the macro generates:

  - `endpoint_name/N` - Returns `{:ok, result}` or `{:error, reason}`
  - `endpoint_name!/N` - Returns `result` or raises on error

  For endpoints with storage enabled:

  - `fetch_endpoint_name/N` - Fetch and persist to storage
  - `fetch_endpoint_name!/N` - Fetch, persist, and raise on error

  ## Parameter Handling

  Function signatures are generated based on endpoint metadata:

  - No params: `endpoint_name()` / `endpoint_name!()`
  - Optional only: `endpoint_name(opts \\\\ [])` / `endpoint_name!(opts \\\\ [])`
  - Required + optional: `endpoint_name(param1, param2, opts \\\\ [])`
  - Required only: `endpoint_name(param1, param2)`
  """

  alias Hyperliquid.Api.Registry

  @doc """
  Converts an endpoint module name to a snake_case function name atom.

  ## Examples

      iex> module_to_function_name(Hyperliquid.Api.Info.AllMids)
      :all_mids

      iex> module_to_function_name(Hyperliquid.Api.Info.L2Book)
      :l2_book

      iex> module_to_function_name(Hyperliquid.Api.Info.ClearinghouseState)
      :clearinghouse_state
  """
  def module_to_function_name(endpoint_module) do
    endpoint_module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> String.to_atom()
  end

  @doc """
  Generates delegated functions for all endpoints in the given context.

  ## Parameters

  - `context` - Atom: `:info`, `:exchange`, `:explorer`, or `:stats`

  ## Generated Code

  For each endpoint module in the context that exports `__endpoint_info__/0`,
  generates wrapper functions with proper signatures, docs, and specs.
  """
  defmacro generate_delegated_functions(context) do
    endpoint_modules = Registry.list_context_endpoints(context)

    function_definitions =
      for endpoint_module <- endpoint_modules do
        # Ensure module is compiled at macro expansion time
        Code.ensure_compiled!(endpoint_module)

        if function_exported?(endpoint_module, :__endpoint_info__, 0) do
          info = endpoint_module.__endpoint_info__()
          params = info.params
          optional_params = info.optional_params

          has_storage =
            function_exported?(endpoint_module, :storage_enabled?, 0) &&
              endpoint_module.storage_enabled?()

          function_name = module_to_function_name(endpoint_module)

          generate_function_variants(
            endpoint_module,
            function_name,
            info,
            params,
            optional_params,
            has_storage
          )
        end
      end

    # Flatten and filter nil results
    function_definitions
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> then(fn defs ->
      quote do
        (unquote_splicing(defs))
      end
    end)
  end

  # Generate function variants based on parameter configuration
  defp generate_function_variants(
         endpoint_module,
         function_name,
         info,
         params,
         optional_params,
         has_storage
       ) do
    cond do
      # Case 1: No parameters
      Enum.empty?(params) && Enum.empty?(optional_params) ->
        generate_no_params(endpoint_module, function_name, info, has_storage)

      # Case 2: Optional params only
      Enum.empty?(params) && !Enum.empty?(optional_params) ->
        generate_optional_only(endpoint_module, function_name, info, optional_params, has_storage)

      # Case 3: Required params (with or without optional)
      true ->
        generate_with_required(
          endpoint_module,
          function_name,
          info,
          params,
          optional_params,
          has_storage
        )
    end
  end

  # Generate functions for endpoints with no parameters
  defp generate_no_params(endpoint_module, function_name, info, has_storage) do
    bang_name = :"#{function_name}!"
    fetch_name = :"fetch_#{function_name}"
    fetch_bang_name = :"fetch_#{function_name}!"

    doc = info.doc
    returns = info.returns
    module_inspect = inspect(endpoint_module)

    base = [
      quote do
        @doc """
        #{unquote(doc)}

        Delegates to `#{unquote(module_inspect)}.request/0`.

        ## Returns

        #{unquote(returns)}

        ## Examples

            {:ok, result} = #{unquote(function_name)}()
        """
        @spec unquote(function_name)() :: {:ok, struct()} | {:error, term()}
        def unquote(function_name)() do
          unquote(endpoint_module).request()
        end
      end,
      quote do
        @doc """
        #{unquote(doc)} (bang variant)

        Delegates to `#{unquote(module_inspect)}.request!/0`.

        Raises on error.
        """
        @spec unquote(bang_name)() :: struct()
        def unquote(bang_name)() do
          unquote(endpoint_module).request!()
        end
      end
    ]

    storage =
      if has_storage do
        [
          quote do
            @doc """
            #{unquote(doc)}

            Fetches data and persists to configured storage backends.

            Delegates to `#{unquote(module_inspect)}.fetch/0`.
            """
            @spec unquote(fetch_name)() :: {:ok, struct()} | {:error, term()}
            def unquote(fetch_name)() do
              unquote(endpoint_module).fetch()
            end
          end,
          quote do
            @doc """
            #{unquote(doc)} (fetch bang variant)

            Fetches data, persists to storage, and raises on error.

            Delegates to `#{unquote(module_inspect)}.fetch!/0`.
            """
            @spec unquote(fetch_bang_name)() :: struct()
            def unquote(fetch_bang_name)() do
              unquote(endpoint_module).fetch!()
            end
          end
        ]
      else
        []
      end

    base ++ storage
  end

  # Generate functions for endpoints with optional params only
  defp generate_optional_only(endpoint_module, function_name, info, optional_params, has_storage) do
    bang_name = :"#{function_name}!"
    fetch_name = :"fetch_#{function_name}"
    fetch_bang_name = :"fetch_#{function_name}!"

    doc = info.doc
    returns = info.returns
    module_inspect = inspect(endpoint_module)
    optional_inspect = inspect(optional_params)

    base = [
      quote do
        @doc """
        #{unquote(doc)}

        Delegates to `#{unquote(module_inspect)}.request/1`.

        ## Parameters

        - `opts` - Optional parameters: #{unquote(optional_inspect)}

        ## Returns

        #{unquote(returns)}
        """
        @spec unquote(function_name)(keyword()) :: {:ok, struct()} | {:error, term()}
        def unquote(function_name)(opts \\ []) do
          unquote(endpoint_module).request(opts)
        end
      end,
      quote do
        @doc """
        #{unquote(doc)} (bang variant)

        Delegates to `#{unquote(module_inspect)}.request!/1`.

        Raises on error.
        """
        @spec unquote(bang_name)(keyword()) :: struct()
        def unquote(bang_name)(opts \\ []) do
          unquote(endpoint_module).request!(opts)
        end
      end
    ]

    storage =
      if has_storage do
        [
          quote do
            @doc """
            #{unquote(doc)}

            Fetches data and persists to configured storage backends.

            Delegates to `#{unquote(module_inspect)}.fetch/1`.
            """
            @spec unquote(fetch_name)(keyword()) :: {:ok, struct()} | {:error, term()}
            def unquote(fetch_name)(opts \\ []) do
              unquote(endpoint_module).fetch(opts)
            end
          end,
          quote do
            @doc """
            #{unquote(doc)} (fetch bang variant)

            Delegates to `#{unquote(module_inspect)}.fetch!/1`.
            """
            @spec unquote(fetch_bang_name)(keyword()) :: struct()
            def unquote(fetch_bang_name)(opts \\ []) do
              unquote(endpoint_module).fetch!(opts)
            end
          end
        ]
      else
        []
      end

    base ++ storage
  end

  # Generate functions for endpoints with required params
  defp generate_with_required(
         endpoint_module,
         function_name,
         info,
         params,
         optional_params,
         has_storage
       ) do
    bang_name = :"#{function_name}!"
    fetch_name = :"fetch_#{function_name}"
    fetch_bang_name = :"fetch_#{function_name}!"

    doc = info.doc
    returns = info.returns
    module_inspect = inspect(endpoint_module)
    needs_opts = !Enum.empty?(optional_params)
    optional_inspect = inspect(optional_params)

    # Build parameter variables for function signature
    param_vars = for param <- params, do: Macro.var(param, nil)
    param_count = length(params)

    # Build param documentation
    param_docs =
      params
      |> Enum.map(fn p -> "- `#{p}` - Required parameter" end)
      |> Enum.join("\n")

    # Generate type specs for params
    param_types = Enum.map(params, fn _ -> quote(do: term()) end)

    if needs_opts do
      arity = param_count + 1

      base = [
        quote do
          @doc """
          #{unquote(doc)}

          Delegates to `#{unquote(module_inspect)}.request/#{unquote(arity)}`.

          ## Parameters

          #{unquote(param_docs)}
          - `opts` - Optional parameters: #{unquote(optional_inspect)}

          ## Returns

          #{unquote(returns)}
          """
          @spec unquote(function_name)(unquote_splicing(param_types), keyword()) ::
                  {:ok, struct()} | {:error, term()}
          def unquote(function_name)(unquote_splicing(param_vars), opts \\ []) do
            unquote(endpoint_module).request(unquote_splicing(param_vars), opts)
          end
        end,
        quote do
          @doc """
          #{unquote(doc)} (bang variant)

          Delegates to `#{unquote(module_inspect)}.request!/#{unquote(arity)}`.

          Raises on error.
          """
          @spec unquote(bang_name)(unquote_splicing(param_types), keyword()) :: struct()
          def unquote(bang_name)(unquote_splicing(param_vars), opts \\ []) do
            unquote(endpoint_module).request!(unquote_splicing(param_vars), opts)
          end
        end
      ]

      storage =
        if has_storage do
          [
            quote do
              @doc """
              #{unquote(doc)}

              Fetches data and persists to configured storage backends.

              Delegates to `#{unquote(module_inspect)}.fetch/#{unquote(arity)}`.
              """
              @spec unquote(fetch_name)(unquote_splicing(param_types), keyword()) ::
                      {:ok, struct()} | {:error, term()}
              def unquote(fetch_name)(unquote_splicing(param_vars), opts \\ []) do
                unquote(endpoint_module).fetch(unquote_splicing(param_vars), opts)
              end
            end,
            quote do
              @doc """
              #{unquote(doc)} (fetch bang variant)

              Delegates to `#{unquote(module_inspect)}.fetch!/#{unquote(arity)}`.
              """
              @spec unquote(fetch_bang_name)(unquote_splicing(param_types), keyword()) :: struct()
              def unquote(fetch_bang_name)(unquote_splicing(param_vars), opts \\ []) do
                unquote(endpoint_module).fetch!(unquote_splicing(param_vars), opts)
              end
            end
          ]
        else
          []
        end

      base ++ storage
    else
      # Required params only, no optional
      arity = param_count

      base = [
        quote do
          @doc """
          #{unquote(doc)}

          Delegates to `#{unquote(module_inspect)}.request/#{unquote(arity)}`.

          ## Parameters

          #{unquote(param_docs)}

          ## Returns

          #{unquote(returns)}
          """
          @spec unquote(function_name)(unquote_splicing(param_types)) ::
                  {:ok, struct()} | {:error, term()}
          def unquote(function_name)(unquote_splicing(param_vars)) do
            unquote(endpoint_module).request(unquote_splicing(param_vars))
          end
        end,
        quote do
          @doc """
          #{unquote(doc)} (bang variant)

          Delegates to `#{unquote(module_inspect)}.request!/#{unquote(arity)}`.

          Raises on error.
          """
          @spec unquote(bang_name)(unquote_splicing(param_types)) :: struct()
          def unquote(bang_name)(unquote_splicing(param_vars)) do
            unquote(endpoint_module).request!(unquote_splicing(param_vars))
          end
        end
      ]

      storage =
        if has_storage do
          [
            quote do
              @doc """
              #{unquote(doc)}

              Fetches data and persists to configured storage backends.

              Delegates to `#{unquote(module_inspect)}.fetch/#{unquote(arity)}`.
              """
              @spec unquote(fetch_name)(unquote_splicing(param_types)) ::
                      {:ok, struct()} | {:error, term()}
              def unquote(fetch_name)(unquote_splicing(param_vars)) do
                unquote(endpoint_module).fetch(unquote_splicing(param_vars))
              end
            end,
            quote do
              @doc """
              #{unquote(doc)} (fetch bang variant)

              Delegates to `#{unquote(module_inspect)}.fetch!/#{unquote(arity)}`.
              """
              @spec unquote(fetch_bang_name)(unquote_splicing(param_types)) :: struct()
              def unquote(fetch_bang_name)(unquote_splicing(param_vars)) do
                unquote(endpoint_module).fetch!(unquote_splicing(param_vars))
              end
            end
          ]
        else
          []
        end

      base ++ storage
    end
  end
end
