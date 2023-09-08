defmodule Dbb.Schema do
  defmodule InvalidConfigFileError do
    defexception message: "invalid config json file"
  end

  alias Dbb.Cache

  @schema_format %{
    schemas: [
      %{
        name: :string,
        description?: :string,
        fields: %{
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
end
