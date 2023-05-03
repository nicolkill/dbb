defmodule DbbWeb.TableJSON do
  alias Dbb.Content.Table

  @doc """
  Renders a list of table.
  """
  def index(%{table: table}) do
    %{data: for(table <- table, do: data(table))}
  end

  @doc """
  Renders a single table.
  """
  def show(%{table: table}) do
    %{data: data(table)}
  end

  defp data(%Table{} = table) do
    %{
      id: table.id,
      schema: table.schema,
      reference: table.reference,
      data: table.data
    }
  end
end
