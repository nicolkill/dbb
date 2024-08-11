defmodule Dbb.Seed do
  @spec generate(integer()) :: any()
  def generate(count) do
    Schema.get_config()
    |> IO.inspect(label: "!!!!!!!!!!!!")
    |> Map.get("schemas")
    |> Enum.map(fn %{"name" => schema_name, "fields" => fields} ->
      fields = Map.to_list(fields)

      records_count = :rand.uniform(count) + 1

      Enum.map(0..records_count, fn _ ->
        generated_data =
          Enum.reduce(fields, %{}, fn {k, v}, acc ->
            Map.put(acc, k, Mix.Tasks.Dbb.Seed.Generator.generate(v))
          end)

        Content.create_table_record(schema_name, generated_data)
      end)
    end)
  end

  defmodule Generator do
    alias Ecto.UUID
    alias Dbb.Utils

    def generate("string") do
      4
      |> :rand.uniform()
      |> Kernel.+(4)
      |> Utils.gen_str_letters()
    end

    def generate("number") do
      :rand.uniform(100)
    end

    def generate("date") do
      year = :rand.uniform(124) + 1900
      month = :rand.uniform(12)
      day = :rand.uniform(28)
      "#{year}-#{month}-#{day}"
    end

    def generate("time") do
      hour = :rand.uniform(24)
      minute = :rand.uniform(59)
      second = :rand.uniform(59)
      "#{hour}:#{minute}#{second}"
    end

    def generate("datetime") do
      "#{generate("date")}T#{generate("time")}"
    end

    def generate("boolean") do
      :rand.uniform(2) - 1 == 0
    end

    def generate("uuid") do
      UUID.generate()
    end

    def generate(list_type) when is_list(list_type) do
      Enum.map(0..:rand.uniform(10), fn _ ->
        list_type
        |> Enum.random()
        |> generate()
      end)
    end
  end
end
