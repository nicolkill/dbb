defmodule Dbb.Schema do
  defmodule InvalidConfigFileError do
    defexception message: "invalid config json file"
  end

  alias Dbb.Cache

  @schema_format %{
    ui?: %{
      title: :string
    },
    schemas: [
      %{
        name: :string,
        description?: :string,
        fields: %{
          string: :string
        },
        generate?: %{
          string: :string
        },
        hooks?: [
          %{
            events: [:string],
            headers: %{
              string: :string
            },
            method: :string,
            url: :string
          }
        ]
      }
    ]
  }
  @key :schema_config

  @type hook :: %{
          events: [String.t()],
          headers: %{String.t() => String.t()},
          method: String.t(),
          url: String.t()
        }
  @type schema :: %{
          fields: %{String.t() => String.t()},
          hooks: [hook()]
        }
  @type config :: %{
          schemas: [schema()]
        }

  defp default_value("number"), do: 0
  defp default_value("float"), do: 0.0
  defp default_value("integer"), do: 0
  defp default_value("boolean"), do: true
  defp default_value("time"), do: Time.utc_now()
  defp default_value("date"), do: Date.utc_today()
  defp default_value("datetime"), do: NaiveDateTime.utc_now()
  defp default_value("string"), do: ""
  defp default_value(data) when is_list(data), do: data |> Enum.map(&default_value/1)

  def field_type_to_input_type("number"), do: "number"
  def field_type_to_input_type("float"), do: "number"
  def field_type_to_input_type("integer"), do: "number"
  def field_type_to_input_type("boolean"), do: "checkbox"
  def field_type_to_input_type("time"), do: "time"
  def field_type_to_input_type("date"), do: "date"
  def field_type_to_input_type("datetime"), do: "datetime-local"
  def field_type_to_input_type("string"), do: "text"
  def field_type_to_input_type(data) when is_list(data), do: "text"

  def value_to_type("", _), do: ""

  def value_to_type(value, type)
      when type in ["number", "float", "integer"] and is_bitstring(value) do
    String.to_float(value)
  rescue
    _ ->
      String.to_integer(value)
  end

  def value_to_type(value, "boolean") when is_bitstring(value),
    do: value == "true" or value == "1"

  def value_to_type(value, "time") when is_bitstring(value), do: Time.from_iso8601!(value)
  def value_to_type(value, "date") when is_bitstring(value), do: Date.from_iso8601!(value)

  def value_to_type(value, "datetime") when is_bitstring(value) do
    <<_::80, 84, _::16, 58, _::16>> = value
    NaiveDateTime.from_iso8601!("#{value}:00")
  rescue
    _ ->
      <<_::80, 84, _::16, 58, _::16, 58, _::16>> = value
      NaiveDateTime.from_iso8601!(value)
  end

  def value_to_type(value, _), do: value

  defp file, do: Application.get_env(:dbb, :general_config)[:file]

  def load_config() do
    config =
      file()
      |> File.read!()
      |> Jason.decode!()

    case MapSchemaValidator.validate(@schema_format, config) do
      {:ok, _} ->
        Cache.save_data(@key, config)
        Dbb.Swagger.generate_swagger(config)

      {:error, %MapSchemaValidator.InvalidMapError{message: message}} ->
        raise InvalidConfigFileError, message: message
    end
  end

  @spec get_config() :: config()
  def get_config() do
    case Cache.get_data(@key) do
      {:ok, cache} -> cache
      _ -> nil
    end
  end

  @spec schema_default_record(schema()) :: map()
  def schema_default_record(%{"fields" => fields}) do
    Enum.reduce(fields, %{}, fn {key, type}, acc ->
      Map.put(acc, key, default_value(type))
    end)
  end
end
