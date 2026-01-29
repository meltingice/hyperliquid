defmodule Hyperliquid.Utils do
  @moduledoc """
  Provides utility functions for the Hyperliquid application.

  This module offers a collection of helper functions that are used across the
  Hyperliquid application. It includes utilities for data manipulation,
  PubSub operations, number formatting, random ID generation, and hexadecimal
  conversions.

  ## Key Features

  - Atomize keys in data structures
  - PubSub subscription and broadcasting
  - Number to string conversions with special float handling
  - Random client order ID (cloid) generation
  - Hexadecimal string manipulations
  - Timestamp generation
  """

  @pubsub Hyperliquid.PubSub

  def subscribe(channel) do
    Phoenix.PubSub.subscribe(@pubsub, channel)
  end

  @doc """
  Convert a hex string (0x-prefixed) to an integer.
  Pass-through for integers and nil.
  """
  @spec to_int(String.t() | integer() | nil) :: integer() | nil
  def to_int("0x" <> hex) do
    {int, ""} = Integer.parse(hex, 16)
    int
  end

  def to_int(int) when is_integer(int), do: int
  def to_int(nil), do: nil

  @doc """
  Convert a non-negative integer to a 0x-prefixed lowercase hex string.
  """
  @spec from_int(non_neg_integer()) :: String.t()
  def from_int(int) when is_integer(int) and int >= 0 do
    "0x" <> String.downcase(Integer.to_string(int, 16))
  end

  def numbers_to_strings(struct, fields) do
    Enum.reduce(fields, struct, fn field, acc ->
      value = Map.get(acc, field)
      Map.put(acc, field, float_to_string(value))
    end)
  end

  def float_to_string(value) when is_float(value) do
    if value == trunc(value) do
      Integer.to_string(trunc(value))
    else
      Float.to_string(value)
    end
  end

  def float_to_string(value) when is_integer(value) do
    Integer.to_string(value)
  end

  def float_to_string(value) when is_binary(value) do
    case Float.parse(value) do
      {float_value, ""} -> float_to_string(float_value)
      :error -> value
    end
  end

  def make_cloid do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end

  def hex_string_to_integer(hex_string) do
    hex_string
    |> String.trim_leading("0x")
    |> Base.decode16!(case: :lower)
    |> :binary.decode_unsigned()
  end

  def to_hex(number) when is_nil(number), do: nil

  def to_hex(number) when is_number(number) do
    Integer.to_string(number, 16)
    |> String.downcase()
    |> then(&"0x#{&1}")
  end

  def to_full_hex(number) when is_number(number) do
    Integer.to_string(number, 16)
    |> String.downcase()
    |> then(&"0x#{String.duplicate("0", 40 - String.length(&1))}#{&1}")
  end

  def trim_0x(nil), do: nil
  def trim_0x(string), do: Regex.replace(~r/^0x/, string, "")

  def get_timestamp, do: :os.system_time(:millisecond)

  @doc """
  Utils for converting map keys to atoms.
  """
  def atomize_keys(data) when is_map(data) do
    Enum.reduce(data, %{}, fn {key, value}, acc ->
      atom_key = if is_binary(key), do: String.to_atom(key), else: key
      Map.put(acc, atom_key, atomize_keys(value))
    end)
  end

  def atomize_keys(data) when is_list(data) do
    Enum.map(data, &atomize_keys/1)
  end

  def atomize_keys({key, value}) when is_binary(key) do
    atom_key = String.to_atom(key)
    {atom_key, atomize_keys(value)}
  end

  def atomize_keys({key, value}) do
    {key, atomize_keys(value)}
  end

  def atomize_keys(data), do: data

  # ===================== Case Conversion =====================

  @doc """
  Convert struct/map to camelCase map recursively (for JSONB storage).

  Drops internal Ecto fields like :__meta__ and :id.

  ## Examples

      iex> Hyperliquid.Utils.to_camel_case_map(%{account_value: "100", total_ntl_pos: "50"})
      %{"accountValue" => "100", "totalNtlPos" => "50"}
  """
  def to_camel_case_map(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__, :id])
    |> to_camel_case_map()
  end

  def to_camel_case_map(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      key = k |> to_string() |> snake_to_camel()
      {key, to_camel_case_map(v)}
    end)
  end

  def to_camel_case_map(list) when is_list(list), do: Enum.map(list, &to_camel_case_map/1)
  def to_camel_case_map(value), do: value

  @doc """
  Convert snake_case string to camelCase.

  ## Examples

      iex> Hyperliquid.Utils.snake_to_camel("account_value")
      "accountValue"

      iex> Hyperliquid.Utils.snake_to_camel("total_ntl_pos")
      "totalNtlPos"
  """
  def snake_to_camel(string) do
    string
    |> String.split("_")
    |> case do
      [first | rest] -> first <> Enum.map_join(rest, &String.capitalize/1)
      [] -> ""
    end
  end
end
