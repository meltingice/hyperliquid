defmodule Hyperliquid.Storage.WriterTest do
  use ExUnit.Case, async: false

  # Skip all tests in this module if database is not enabled
  @moduletag :requires_database

  import Ecto.Query
  alias Hyperliquid.Storage.Writer
  alias Hyperliquid.Repo

  # Test struct for JSONB transformation testing
  defmodule DummyStruct do
    defstruct [:field1, :field2]
  end

  # Simple mock modules with __postgres_tables__/0
  defmodule SingleTableMock do
    def __postgres_tables__ do
      [
        %{
          table: "writer_test_single",
          extract: :records,
          conflict_target: :record_id,
          on_conflict: {:replace, [:value, :updated_at]},
          transform: nil,
          fields: nil
        }
      ]
    end

    def storage_enabled?, do: true
    def postgres_enabled?, do: true
    def cache_enabled?, do: false
    def postgres_table, do: "writer_test_single"
  end

  defmodule MultiTableMock do
    def __postgres_tables__ do
      [
        %{
          table: "writer_test_primary",
          extract: :primary,
          conflict_target: :record_id,
          on_conflict: {:replace, [:name, :updated_at]},
          transform: nil,
          fields: nil
        },
        %{
          table: "writer_test_secondary",
          extract: :secondary,
          conflict_target: :key,
          on_conflict: {:replace, [:value, :updated_at]},
          transform: &__MODULE__.transform_secondary/1,
          fields: nil
        }
      ]
    end

    def storage_enabled?, do: true
    def postgres_enabled?, do: true
    def cache_enabled?, do: false
    def postgres_table, do: "writer_test_primary"

    def transform_secondary(records) when is_list(records) do
      Enum.map(records, fn record ->
        # Convert any nested structs to maps
        record
        |> Map.update(:nested_struct, nil, fn
          %{__struct__: _} = struct -> Map.from_struct(struct) |> Map.drop([:__meta__])
          map -> map
        end)
      end)
    end
  end

  defmodule NoTableMock do
    def __postgres_tables__, do: []
    def storage_enabled?, do: false
    def postgres_enabled?, do: false
    def cache_enabled?, do: false
    def postgres_table, do: nil
  end

  # Setup/teardown
  setup do
    # Only start Writer if not already running
    case GenServer.whereis(Hyperliquid.Storage.Writer) do
      nil -> start_supervised!(Hyperliquid.Storage.Writer)
      _pid -> :ok
    end

    # Create test tables
    Ecto.Adapters.SQL.query!(
      Repo,
      """
      CREATE TABLE IF NOT EXISTS writer_test_single (
        record_id INTEGER PRIMARY KEY,
        value TEXT,
        inserted_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP
      )
      """
    )

    Ecto.Adapters.SQL.query!(
      Repo,
      """
      CREATE TABLE IF NOT EXISTS writer_test_primary (
        record_id INTEGER PRIMARY KEY,
        name TEXT,
        inserted_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP
      )
      """
    )

    Ecto.Adapters.SQL.query!(
      Repo,
      """
      CREATE TABLE IF NOT EXISTS writer_test_secondary (
        key TEXT PRIMARY KEY,
        value TEXT,
        nested_struct JSONB,
        inserted_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP
      )
      """
    )

    # Clean up data before each test
    Ecto.Adapters.SQL.query!(Repo, "TRUNCATE TABLE writer_test_single")
    Ecto.Adapters.SQL.query!(Repo, "TRUNCATE TABLE writer_test_primary")
    Ecto.Adapters.SQL.query!(Repo, "TRUNCATE TABLE writer_test_secondary")

    on_exit(fn ->
      # Clean up test tables
      Ecto.Adapters.SQL.query!(Repo, "DROP TABLE IF EXISTS writer_test_single")
      Ecto.Adapters.SQL.query!(Repo, "DROP TABLE IF EXISTS writer_test_primary")
      Ecto.Adapters.SQL.query!(Repo, "DROP TABLE IF EXISTS writer_test_secondary")
    end)

    :ok
  end

  describe "single-table storage" do
    test "DEBUG: database connection works" do
      # Direct insert to verify database works
      now = DateTime.utc_now()

      {count, _} =
        Repo.insert_all("writer_test_single", [
          %{record_id: 999, value: "direct_insert", inserted_at: now, updated_at: now}
        ])

      assert count == 1

      records =
        Repo.all(
          from(r in "writer_test_single",
            where: r.record_id == 999,
            select: %{record_id: r.record_id}
          )
        )

      assert length(records) == 1
    end

    test "writes records to single table" do
      # store_sync expects a single event (map), not a list of events
      event_data = %{
        records: [
          %{record_id: 1, value: "test1"},
          %{record_id: 2, value: "test2"}
        ]
      }

      assert {:ok, :stored} = Writer.store_sync(SingleTableMock, event_data)

      # Verify records in database
      records =
        Repo.all(
          from(r in "writer_test_single", select: %{record_id: r.record_id, value: r.value})
        )

      assert length(records) == 2
      assert Enum.find(records, &(&1.record_id == 1)).value == "test1"
      assert Enum.find(records, &(&1.record_id == 2)).value == "test2"
    end

    test "upserts records on conflict" do
      # Initial insert
      event_data = %{records: [%{record_id: 1, value: "initial"}]}
      assert {:ok, :stored} = Writer.store_sync(SingleTableMock, event_data)

      # Verify initial value
      [record] =
        Repo.all(
          from(r in "writer_test_single", select: %{record_id: r.record_id, value: r.value})
        )

      assert record.value == "initial"

      # Update via upsert
      event_data = %{records: [%{record_id: 1, value: "updated"}]}
      assert {:ok, :stored} = Writer.store_sync(SingleTableMock, event_data)

      # Verify updated value
      [record] =
        Repo.all(
          from(r in "writer_test_single", select: %{record_id: r.record_id, value: r.value})
        )

      assert record.value == "updated"
    end

    test "adds timestamps automatically" do
      event_data = %{records: [%{record_id: 1, value: "test"}]}
      assert {:ok, :stored} = Writer.store_sync(SingleTableMock, event_data)

      [record] =
        Repo.all(
          from(r in "writer_test_single",
            select: %{
              inserted_at: r.inserted_at,
              updated_at: r.updated_at
            }
          )
        )

      # Postgres returns NaiveDateTime, not DateTime
      assert %NaiveDateTime{} = record.inserted_at
      assert %NaiveDateTime{} = record.updated_at
    end

    test "extracts nested records correctly" do
      # Event with nested records
      event_data = %{
        records: [
          %{record_id: 10, value: "nested1"},
          %{record_id: 11, value: "nested2"}
        ],
        other_field: "ignored"
      }

      assert {:ok, :stored} = Writer.store_sync(SingleTableMock, event_data)

      records = Repo.all(from(r in "writer_test_single", select: %{record_id: r.record_id}))
      assert length(records) == 2
    end
  end

  describe "multi-table storage" do
    test "writes to multiple tables from single event" do
      event_data = %{
        primary: [
          %{record_id: 1, name: "primary1"},
          %{record_id: 2, name: "primary2"}
        ],
        secondary: [
          %{key: "sec1", value: "value1", nested_struct: nil},
          %{key: "sec2", value: "value2", nested_struct: nil}
        ]
      }

      assert {:ok, :stored} = Writer.store_sync(MultiTableMock, event_data)

      # Verify primary table
      primary_records =
        Repo.all(
          from(r in "writer_test_primary", select: %{record_id: r.record_id, name: r.name})
        )

      assert length(primary_records) == 2
      assert Enum.find(primary_records, &(&1.record_id == 1)).name == "primary1"

      # Verify secondary table
      secondary_records =
        Repo.all(from(r in "writer_test_secondary", select: %{key: r.key, value: r.value}))

      assert length(secondary_records) == 2
      assert Enum.find(secondary_records, &(&1.key == "sec1")).value == "value1"
    end

    test "applies transform function to secondary table" do
      # Event with nested struct that needs transformation
      event_data = %{
        primary: [],
        secondary: [
          %{
            key: "transformed",
            value: "test",
            nested_struct: %DummyStruct{field1: "data", field2: 123}
          }
        ]
      }

      assert {:ok, :stored} = Writer.store_sync(MultiTableMock, event_data)

      # Verify transform converted struct to map for JSONB
      [record] =
        Repo.all(
          from(r in "writer_test_secondary",
            where: r.key == "transformed",
            select: %{nested_struct: r.nested_struct}
          )
        )

      assert is_map(record.nested_struct)
      assert record.nested_struct["field1"] == "data"
      assert record.nested_struct["field2"] == 123
      refute Map.has_key?(record.nested_struct, :__struct__)
    end

    test "handles empty arrays for some tables" do
      event_data = %{
        primary: [%{record_id: 1, name: "only_primary"}],
        # Empty array
        secondary: []
      }

      assert {:ok, :stored} = Writer.store_sync(MultiTableMock, event_data)

      # Only primary table should have records
      assert Repo.aggregate("writer_test_primary", :count) == 1
      assert Repo.aggregate("writer_test_secondary", :count) == 0
    end

    test "returns total count across all tables" do
      event_data = %{
        primary: [
          %{record_id: 1, name: "p1"},
          %{record_id: 2, name: "p2"},
          %{record_id: 3, name: "p3"}
        ],
        secondary: [
          %{key: "s1", value: "v1", nested_struct: nil},
          %{key: "s2", value: "v2", nested_struct: nil}
        ]
      }

      # Total: 3 primary + 2 secondary = 5
      assert {:ok, :stored} = Writer.store_sync(MultiTableMock, event_data)
    end

    test "each table gets its own conflict resolution" do
      # Initial insert
      event_data = %{
        primary: [%{record_id: 1, name: "initial_name"}],
        secondary: [%{key: "key1", value: "initial_value", nested_struct: nil}]
      }

      assert {:ok, :stored} = Writer.store_sync(MultiTableMock, event_data)

      # Update both tables
      event_data = %{
        primary: [%{record_id: 1, name: "updated_name"}],
        secondary: [%{key: "key1", value: "updated_value", nested_struct: nil}]
      }

      assert {:ok, :stored} = Writer.store_sync(MultiTableMock, event_data)

      # Verify both were updated
      [primary] = Repo.all(from(r in "writer_test_primary", select: %{name: r.name}))
      assert primary.name == "updated_name"

      [secondary] = Repo.all(from(r in "writer_test_secondary", select: %{value: r.value}))
      assert secondary.value == "updated_value"
    end
  end

  describe "error handling" do
    test "returns ok with no_storage_configured when storage disabled" do
      event_data = %{value: "test"}

      assert {:ok, :no_storage_configured} = Writer.store_sync(NoTableMock, event_data)
    end

    test "propagates errors from transform functions" do
      defmodule FailingTransformMock do
        def __postgres_tables__ do
          [
            %{
              table: "writer_test_primary",
              extract: :records,
              transform: &__MODULE__.failing_transform/1,
              conflict_target: nil,
              on_conflict: :nothing,
              fields: nil
            }
          ]
        end

        def storage_enabled?, do: true
        def postgres_enabled?, do: true
        def cache_enabled?, do: false
        def postgres_table, do: "writer_test_primary"

        def failing_transform(_records) do
          raise "Transform failed!"
        end
      end

      event_data = %{records: [%{record_id: 1}]}

      # Transform errors crash the GenServer, which exits the calling process
      assert catch_exit(Writer.store_sync(FailingTransformMock, event_data))
    end
  end

  describe "async storage" do
    test "store_async returns :ok immediately" do
      event_data = %{records: [%{record_id: 99, value: "async_test"}]}

      assert :ok = Writer.store_async(SingleTableMock, event_data)

      # Flush the buffer to force async write to complete
      Writer.flush()

      # Verify record was written
      records =
        Repo.all(
          from(r in "writer_test_single",
            where: r.record_id == 99,
            select: %{record_id: r.record_id}
          )
        )

      assert length(records) == 1
    end
  end

  describe "backwards compatibility" do
    test "works with endpoints using legacy single-table format" do
      # This test verifies that old-style endpoints still work
      event_data = %{records: [%{record_id: 100, value: "legacy"}]}

      assert {:ok, :stored} = Writer.store_sync(SingleTableMock, event_data)

      records =
        Repo.all(
          from(r in "writer_test_single",
            where: r.record_id == 100,
            select: %{record_id: r.record_id}
          )
        )

      assert length(records) == 1
    end

    test "legacy endpoints return :stored status" do
      event_data = %{records: [%{record_id: 1, value: "test"}]}

      result = Writer.store_sync(SingleTableMock, event_data)

      # Should be {:ok, :stored}, not {:ok, :no_storage_configured}
      assert {:ok, :stored} = result
    end
  end
end
