defmodule Mix.Tasks.Hyperliquid.Gen.Schemas do
  use Mix.Task

  @shortdoc "Generate Ecto schemas from TypeScript Hyperliquid SDK types"

  @moduledoc """
  Generates Elixir Ecto schemas from the @nktkas/hyperliquid TypeScript SDK.

  This task helps maintain type parity between the TypeScript SDK and the Elixir
  implementation by parsing Valibot schemas and generating equivalent Ecto schemas.

  ## Usage

      # Generate all schemas
      mix hyperliquid.gen.schemas

      # Generate specific category
      mix hyperliquid.gen.schemas --category=subscription

      # Generate specific endpoint
      mix hyperliquid.gen.schemas --endpoint=webData2

      # Dry run (don't write files)
      mix hyperliquid.gen.schemas --dry-run

  ## Options

    * `--category` - Generate schemas for a specific category (info, exchange, subscription)
    * `--endpoint` - Generate schema for a specific endpoint
    * `--dry-run` - Show what would be generated without writing files
    * `--ts-sdk-path` - Path to the TypeScript SDK repository (default: ../../../@nktkas_hyperliquid)

  ## Examples

      # Generate all subscription schemas
      mix hyperliquid.gen.schemas --category=subscription

      # Generate only webData2 schema
      mix hyperliquid.gen.schemas --endpoint=webData2 --category=subscription

      # Preview changes without writing
      mix hyperliquid.gen.schemas --dry-run

  ## Architecture

  This generator:
  1. Reads TypeScript files from the @nktkas/hyperliquid SDK
  2. Parses Valibot schemas to extract type information
  3. Generates Elixir Ecto embedded schemas
  4. Writes single-file modules with all nested schemas
  5. Tracks SDK version for future sync checks

  ## Type Mapping

  The following TypeScript/Valibot types are mapped to Elixir/Ecto:

  - `v.string()` → `:string`
  - `v.number()` / `UnsignedInteger` → `:integer`
  - `v.boolean()` → `:boolean`
  - `UnsignedDecimal` / `Decimal` → `:string` (for precision)
  - `v.array(...)` → `{:array, type}` or `embeds_many`
  - `v.object(...)` → `embeds_one` or `embeds_many`
  - `v.record(...)` → `:map`
  - `v.union([...])` → `:string` with validation
  - `Address` → `:string` with regex validation
  - `Hex` → `:string`

  ## Generated File Structure

      lib/hyperliquid/api/
      ├── info/
      │   ├── all_mids.ex
      │   ├── clearinghouse_state.ex
      │   └── ...
      ├── exchange/
      │   ├── order.ex
      │   ├── cancel.ex
      │   └── ...
      └── subscription/
          ├── web_data2.ex
          ├── web_data3.ex
          └── ...

  Each file contains:
  - Request parameter schema
  - Response/Event schema with embedded nested types
  - Changesets for validation
  - Helper functions
  - Usage examples in @moduledoc
  """

  @ts_sdk_default_path Path.expand("../../../../@nktkas_hyperliquid", __DIR__)
  @output_base_path "lib/hyperliquid/api"

  def run(args) do
    {opts, _} =
      OptionParser.parse!(args,
        strict: [
          category: :string,
          endpoint: :string,
          dry_run: :boolean,
          ts_sdk_path: :string
        ]
      )

    ts_sdk_path = opts[:ts_sdk_path] || @ts_sdk_default_path
    category = opts[:category]
    endpoint = opts[:endpoint]
    dry_run = opts[:dry_run] || false

    Mix.shell().info("🚀 Hyperliquid Schema Generator")
    Mix.shell().info("TypeScript SDK: #{ts_sdk_path}")
    Mix.shell().info("")

    case {category, endpoint} do
      {nil, nil} ->
        Mix.shell().info("Generating all schemas...")
        generate_all(ts_sdk_path, dry_run)

      {cat, nil} when cat in ["info", "exchange", "subscription"] ->
        Mix.shell().info("Generating #{cat} schemas...")
        generate_category(ts_sdk_path, cat, dry_run)

      {cat, ep} when not is_nil(cat) and not is_nil(ep) ->
        Mix.shell().info("Generating #{cat}/#{ep} schema...")
        generate_endpoint(ts_sdk_path, cat, ep, dry_run)

      {nil, ep} when not is_nil(ep) ->
        Mix.shell().error("Error: --endpoint requires --category")
        exit({:shutdown, 1})

      _ ->
        Mix.shell().error("Error: Invalid category (must be info, exchange, or subscription)")
        exit({:shutdown, 1})
    end
  end

  # ===================== Generation Functions =====================

  defp generate_all(ts_sdk_path, dry_run) do
    ["info", "exchange", "subscription"]
    |> Enum.each(&generate_category(ts_sdk_path, &1, dry_run))

    Mix.shell().info("")
    Mix.shell().info("✅ Generation complete!")
  end

  defp generate_category(ts_sdk_path, category, dry_run) do
    endpoints = discover_endpoints(ts_sdk_path, category)

    Mix.shell().info("Found #{length(endpoints)} #{category} endpoints")

    endpoints
    |> Enum.each(&generate_endpoint(ts_sdk_path, category, &1, dry_run))
  end

  defp generate_endpoint(ts_sdk_path, category, endpoint, dry_run) do
    ts_file = Path.join([ts_sdk_path, "src", "api", category, "#{endpoint}.ts"])

    unless File.exists?(ts_file) do
      Mix.shell().error("  ✗ TypeScript file not found: #{ts_file}")
      {:error, :not_found}
    end

    # Parse TypeScript file and extract schemas
    case parse_typescript_file(ts_file) do
      {:ok, schema_info} ->
        elixir_module = generate_elixir_module(category, endpoint, schema_info)
        output_file = get_output_path(category, endpoint)

        if dry_run do
          Mix.shell().info("  [DRY RUN] Would write: #{output_file}")
          Mix.shell().info("")
          Mix.shell().info(String.slice(elixir_module, 0, 500) <> "\n  ...")
          Mix.shell().info("")
        else
          File.mkdir_p!(Path.dirname(output_file))
          File.write!(output_file, elixir_module)
          Mix.shell().info("  ✓ Generated: #{output_file}")
        end

        {:ok, output_file}

      {:error, reason} ->
        Mix.shell().error("  ✗ Failed to parse #{endpoint}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ===================== TypeScript Parsing =====================

  defp discover_endpoints(ts_sdk_path, category) do
    src_dir = Path.join([ts_sdk_path, "src", "api", category])

    if File.dir?(src_dir) do
      src_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".ts"))
      |> Enum.reject(&String.starts_with?(&1, "_"))
      |> Enum.map(&String.replace_suffix(&1, ".ts", ""))
      |> Enum.sort()
    else
      []
    end
  end

  defp parse_typescript_file(ts_file) do
    # TODO: Implement full TypeScript/Valibot parser
    # For now, this is a placeholder that would need to:
    # 1. Read the TypeScript file
    # 2. Extract the Request and Response/Event schemas
    # 3. Parse the Valibot schema definitions
    # 4. Extract field names, types, and descriptions
    # 5. Return structured schema information

    case File.read(ts_file) do
      {:ok, content} ->
        schema_info = %{
          module_name: extract_module_name(content),
          request_schema: extract_request_schema(content),
          response_schema: extract_response_schema(content),
          imports: extract_imports(content),
          description: extract_description(content)
        }

        {:ok, schema_info}

      {:error, reason} ->
        {:error, {:file_read_error, ts_file, reason}}
    end
  end

  # ===================== Code Generation =====================

  defp generate_elixir_module(category, endpoint, schema_info) do
    module_name = Macro.camelize(endpoint)
    category_module = Macro.camelize(category)

    """
    defmodule Hyperliquid.Api.#{category_module}.#{module_name} do
      @moduledoc \"\"\"
      #{schema_info.description || "Generated from @nktkas/hyperliquid"}

      Auto-generated from @nktkas/hyperliquid
      Source: src/api/#{category}/#{endpoint}.ts
      \"\"\"
      use Ecto.Schema
      import Ecto.Changeset

      # Request Schema
      #{generate_request_schema(schema_info.request_schema)}

      # Response/Event Schema
      #{generate_response_schema(schema_info.response_schema)}

      # Changesets
      #{generate_changesets(schema_info)}

      # Helper Functions
      #{generate_helpers(category, schema_info)}
    end
    """
  end

  defp generate_request_schema(_schema) do
    # TODO: Generate request validation based on schema
    """
    def build_request(params) do
      # Implementation
    end
    """
  end

  defp generate_response_schema(_schema) do
    # TODO: Generate embedded schemas based on TypeScript types
    """
    @primary_key false
    embedded_schema do
      # Fields will be generated here
    end
    """
  end

  defp generate_changesets(_schema_info) do
    """
    def changeset(struct \\\\ %__MODULE__{}, attrs) do
      # Implementation
    end
    """
  end

  defp generate_helpers(category, _schema_info) do
    case category do
      "subscription" ->
        """
        def subscribe(params, callback) do
          # Implementation
        end
        """

      _ ->
        """
        def request(params) do
          # Implementation
        end
        """
    end
  end

  # ===================== Extraction Helpers =====================

  defp extract_module_name(content) do
    # Extract from export const {Name}Request pattern
    case Regex.run(~r/export const (\w+)Request/, content) do
      [_, name] -> name
      _ -> "Unknown"
    end
  end

  defp extract_request_schema(_content) do
    # TODO: Parse Valibot object schema
    %{}
  end

  defp extract_response_schema(_content) do
    # TODO: Parse Valibot object schema
    %{}
  end

  defp extract_imports(_content) do
    # TODO: Extract import statements for nested types
    []
  end

  defp extract_description(content) do
    # Extract JSDoc description
    case Regex.run(~r/\/\*\* (.+?) \*\//, content, capture: :all_but_first) do
      [desc] -> String.trim(desc)
      _ -> nil
    end
  end

  # ===================== Path Helpers =====================

  defp get_output_path(category, endpoint) do
    filename = Macro.underscore(endpoint) <> ".ex"
    Path.join([@output_base_path, category, filename])
  end
end
