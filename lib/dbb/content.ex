defmodule Dbb.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false
  alias Dbb.Repo

  alias Dbb.Content.Table

  defp dynamic_filters([]), do: true
  defp dynamic_filters([{}]), do: true
  defp dynamic_filters(query) do
    Enum.reduce(query, false, fn
      {key, "null"}, criteria ->
        dynamic([t], is_nil(json_extract_path(t.data, [^key])) or ^criteria)
      {key, "not_null"}, criteria ->
        dynamic([t], not is_nil(json_extract_path(t.data, [^key])) or ^criteria)
      {key, value}, criteria ->
        value =
          value
          |> String.replace("%", "")
          |> String.replace("_", "")
          |> (&("%#{&1}%")).()
        dynamic(
          [t],
          ilike(
            type(
              json_extract_path(t.data, [^key]),
              :string
            ),
            ^value
          ) or ^criteria
        )
    end)
  end

  @doc """
  Returns the list of table.

  ## Examples

      iex> list_table("some_schema")
      [%Table{}, ...]

  """
  @spec list_table(String.t(), list(), number(), number()) :: [Table]
  def list_table(nil, _, _, _), do: []
  def list_table(schema, query, page, count) do
    criteria = dynamic_filters(query)

    offset = ((page + 1) * count) - count

    Table
    |> where(schema: ^schema)
    |> where(^criteria)
    |> limit(^count)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Gets a single table.

  Raises `Ecto.NoResultsError` if the Table does not exist.

  ## Examples

      iex> get_table!("some_schema", 123)
      %Table{}

      iex> get_table!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_table!(String.t(), String.t()) :: Table
  def get_table!(nil, _), do: {:error, :not_found}
  def get_table!(schema, id) do
    Table
    |> where(schema: ^schema)
    |> where([t], is_nil(t.deleted_at))
    |> Repo.get!(id)
  end

  @doc """
  Creates a table.

  ## Examples

      iex> create_table(%{field: value})
      {:ok, %Table{}}

      iex> create_table(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_table(schema, attrs  \\ %{})
  def create_table(nil, _), do: {:error, :not_found}
  def create_table(schema, attrs) do
    key =
      attrs
      |> Map.keys()
      |> Enum.at(0)
      |> is_atom()
      |> if(do: :schema, else: "schema")
    attrs = Map.put(attrs, key, schema)

    %Table{}
    |> Table.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a table.

  ## Examples

      iex> update_table(table, %{field: new_value})
      {:ok, %Table{}}

      iex> update_table(table, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_table(%Table{} = table, attrs) do
    table
    |> Table.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a table.

  ## Examples

      iex> delete_table(table)
      {:ok, %Table{}}

      iex> delete_table(table)
      {:error, %Ecto.Changeset{}}

  """
  def delete_table(%Table{} = table) do
    table
    |> Table.changeset_delete(%{deleted_at: NaiveDateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking table changes.

  ## Examples

      iex> change_table(table)
      %Ecto.Changeset{data: %Table{}}

  """
  def change_table(%Table{} = table, attrs \\ %{}) do
    Table.changeset(table, attrs)
  end
end
