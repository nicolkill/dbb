defmodule Dbb.SchemaManager.ValueValidator do
  @moduledoc """
  Custom value validator that extends MapSchemaValidator with additional types.
  """

  @valid_basic_types [
    :float,
    :integer,
    :number,
    :boolean,
    :string,
    :datetime,
    :date,
    :time,
    :uuid,
    :map
  ]

  def is_valid_value?(type), do: Enum.member?(@valid_basic_types, type)

  def validate_values(:map, json_value, _steps) when is_map(json_value), do: true

  def validate_values(schema_value, json_value, _steps)
      when schema_value == :uuid and is_bitstring(json_value) do
    {:ok, _} = UUID.info(json_value)
    true
  rescue
    _ ->
      false
  end

  def validate_values(schema_value, json_value, _steps)
      when schema_value == :time and is_bitstring(json_value) do
    {:ok, _} = Time.from_iso8601(json_value)
    true
  rescue
    _ ->
      false
  end

  def validate_values(schema_value, %Time{} = _json_value, _steps)
      when schema_value == :time,
      do: true

  def validate_values(schema_value, json_value, _steps)
      when schema_value == :date and is_bitstring(json_value) do
    {:ok, _} = Date.from_iso8601(json_value)
    true
  rescue
    _ ->
      false
  end

  def validate_values(schema_value, %Date{} = _json_value, _steps)
      when schema_value == :date,
      do: true

  def validate_values(schema_value, json_value, _steps)
      when schema_value == :datetime and is_bitstring(json_value) do
    {:ok, _} = NaiveDateTime.from_iso8601(json_value)
    true
  rescue
    _ ->
      false
  end

  def validate_values(schema_value, %NaiveDateTime{} = _json_value, _steps)
      when schema_value == :datetime,
      do: true

  def validate_values(schema_value, json_value, _steps)
      when schema_value == :float and is_float(json_value),
      do: true

  def validate_values(schema_value, json_value, _steps)
      when schema_value == :integer and is_integer(json_value),
      do: true

  def validate_values(schema_value, json_value, _steps)
      when schema_value == :number and is_number(json_value),
      do: true

  def validate_values(schema_value, json_value, _steps)
      when schema_value == :boolean and is_boolean(json_value),
      do: true

  def validate_values(schema_value, json_value, _steps)
      when schema_value == :string and is_bitstring(json_value),
      do: true

  def validate_values(schema_value, json_value, steps)
      when is_list(schema_value) and is_list(json_value),
      do:
        Enum.reduce(json_value, true, fn jv, acc ->
          acc and validate_values(schema_value, jv, steps)
        end)

  def validate_values(schema_value, json_value, steps)
      when is_list(schema_value),
      do: Enum.any?(schema_value, &validate_values(&1, json_value, steps))

  def validate_values(schema_value, json_value, steps)
      when is_list(json_value),
      do: Enum.any?(json_value, &validate_values(schema_value, &1, steps))

  def validate_values(schema_value, json_value, steps)
      when is_map(schema_value) and is_map(json_value),
      do: MapSchemaValidator.validate_json!(schema_value, json_value, steps)

  def validate_values(_schema_value, _json_value, _steps), do: false

  @doc """
  Validates a map against a schema using the custom validator.

  ## Examples

      iex> ValueValidator.validate(%{key: :string}, %{key: "value"})
      {:ok, nil}

      iex> ValueValidator.validate(%{key: :map}, %{key: %{nested: "value"}})
      {:ok, nil}

      iex> ValueValidator.validate(%{key: :map}, %{key: "not a map"})
      {:error, _}
  """
  def validate(schema, json) do
    validate_json!(schema, json)
    {:ok, nil}
  rescue
    e in MapSchemaValidator.InvalidMapError ->
      {:error, e}
  end

  defp params(key) do
    key_string = to_string(key)

    mandatory =
      key_string
      |> String.contains?("?")
      |> Kernel.!()

    key_string = String.replace(key_string, "?", "")
    {mandatory, String.to_atom(key_string)}
  end

  defp iterate([], _schema, _json, _steps), do: true

  defp iterate([key | rest], schema, json, steps) do
    {mandatory, key_core} = params(key)
    schema_value = Map.get(schema, key)
    json_value = Map.get(json, key_core)
    exist_in_json? = Map.has_key?(json, key_core)
    key_is_value? = is_valid_value?(key)

    next =
      case {key_is_value?, exist_in_json?} do
        {true, false} ->
          json
          |> Map.keys()
          |> Enum.reduce(
            true,
            &(&2 and validate_values(key, to_string(&1), steps) and
                validate_values(key, Map.get(json, &1), steps))
          )

        {_, true} ->
          validate_values(schema_value, json_value, steps)

        _ ->
          !mandatory
      end

    if next do
      iterate(rest, schema, json, steps)
    else
      raise MapSchemaValidator.InvalidMapError,
        message: "error at: #{Enum.join(steps ++ [key_core], " -> ")}"
    end
  end

  defp validate_json!(schema, json, steps \\ []) do
    schema_keys = Map.keys(schema)

    corrected_schema = MapSchemaValidator.MapUtils.map_to_atom_keys(schema)
    corrected_json = MapSchemaValidator.MapUtils.map_to_atom_keys(json)

    iterate(schema_keys, corrected_schema, corrected_json, steps)
  end
end
