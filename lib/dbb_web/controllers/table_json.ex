defmodule DbbWeb.TableJSON do
  alias Dbb.Content.Table

  @doc """
  Renders a list of table.
  """
  def index(%{table: table, page: page, count: count}) do
    %{
      page: page,
      count: count,
      data: for(table <- table, do: data(table))
    }
  end

  @doc """
  Renders a single table.
  """
  def show(%{table: table}) do
    %{data: data(table)}
  end

  defp data(%Table{} = table) do
    relations =
      table
      |> Map.get(:relations, %{})
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        Map.put(acc, key, data(value))
      end)

    %{
      id: table.id,
      schema: table.schema,
      relations: relations,
      data: table.data,
      inserted_at: table.inserted_at,
      updated_at: table.updated_at
    }
  end
end
