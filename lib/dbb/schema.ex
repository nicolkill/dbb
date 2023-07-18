defmodule Dbb.Schema do
  alias Dbb.Cache

  @key :schema_config

  defp file, do: Application.get_env(:dbb, :general_config)[:file]

  def load_config() do
    config =
      file()
      |> File.read!()
      |> Jason.decode!()

    #    todo: validate json format

    Cache.save_data(@key, config)
  end

  def get_config() do
    case Cache.get_data(@key) do
      {:ok, cache} -> cache
      _ -> nil
    end
  end
end
