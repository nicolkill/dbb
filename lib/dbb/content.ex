defmodule Dbb.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false

  alias Dbb.Repo
  alias Dbb.Content.Table
  alias Dbb.TableHandler

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
          |> (&"%#{&1}%").()

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

  defp add_relations(record, relations \\ [])

  defp add_relations({:ok, record}, relations) do
    {:ok, add_relations(record, relations)}
  end

  defp add_relations(record, _) when is_tuple(record), do: record

  defp add_relations(record, relations) do
    schema_relations =
      record
      |> Map.get(:schema)
      |> TableHandler.get_relation_schema()

    relations =
      Enum.reduce(relations, %{}, fn r, acc ->
        key = "#{r}_id"
        %{"value" => related_schema} = Map.get(schema_relations, key)

        id =
          record
          |> Map.get(:data)
          |> Map.get(key)

        related_record = get_table_record!(related_schema, id)

        Map.put(acc, related_schema, related_record)
      end)

    Map.put(record, :relations, relations)
  end

  @doc """
  Returns the list of table.

  ## Examples

      iex> list_table_records("some_schema")
      [%Table{}, ...]

  """
  @spec list_table_records(String.t(), list(), number(), number(), list(), boolean()) :: [Table]
  def list_table_records(
        schema,
        query \\ [],
        page \\ 0,
        count \\ 10,
        relations \\ [],
        soft_delete \\ true
      )

  def list_table_records(nil, _, _, _, _, _), do: []

  def list_table_records(schema, query, page, count, relations, soft_delete) do
    criteria = dynamic_filters(query)

    offset = (page + 1) * count - count

    query =
      Table
      |> where(schema: ^schema)
      |> where(^criteria)

    if soft_delete do
      where(query, [t], is_nil(t.deleted_at))
    else
      where(query, [t], not is_nil(t.deleted_at))
    end
    |> limit(^count)
    |> offset(^offset)
    |> Repo.all()
    |> Enum.map(&add_relations(&1, relations))
  end

  @doc """
  Gets a single table.

  Raises `Ecto.NoResultsError` if the Table does not exist.

  ## Examples

      iex> get_table_record!("some_schema", 123)
      %Table{}

      iex> get_table_record!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_table_record!(String.t(), String.t()) :: Table
  def get_table_record!(schema, id, relations \\ [])
  def get_table_record!(nil, _, _), do: {:error, :not_found}

  def get_table_record!(schema, id, relations) do
    Table
    |> where(schema: ^schema)
    |> where([t], is_nil(t.deleted_at))
    |> Repo.get!(id)
    |> add_relations(relations)
  end

  defp is_atom_key(nil), do: true

  defp is_atom_key(attrs),
    do:
      attrs
      |> Map.keys()
      |> Enum.at(0)
      |> is_atom()

  @doc """
  Creates a table.

  ## Examples

      iex> create_table_record(%{field: value})
      {:ok, %Table{}}

      iex> create_table_record(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_table_record(schema, attrs \\ %{})
  def create_table_record(nil, _), do: {:error, :not_found}

  def create_table_record(schema, attrs) do
    {data_key, schema_key} = if is_atom_key(attrs), do: {:data, :schema}, else: {"data", "schema"}

    attrs =
      %{}
      |> Map.put(data_key, attrs)
      |> Map.put(schema_key, schema)

    %Table{}
    |> Table.changeset(attrs)
    |> Repo.insert()
    |> add_relations()
  end

  @doc """
  Updates a table.

  ## Examples

      iex> update_table_record(table, %{field: new_value})
      {:ok, %Table{}}

      iex> update_table_record(table, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_table_record(%Table{data: data} = table, attrs) do
    data_key = if is_atom_key(attrs), do: :data, else: "data"

    attrs =
      case attrs do
        nil ->
          attrs

        attrs ->
          Map.merge(data, attrs)
      end
      |> then(&Map.put(%{}, data_key, &1))

    table
    |> Table.changeset(attrs)
    |> Repo.update()
    |> add_relations()
  end

  @doc """
  Deletes a table.

  ## Examples

      iex> delete_table_record(table)
      {:ok, %Table{}}

      iex> delete_table_record(table)
      {:error, %Ecto.Changeset{}}

  """
  def delete_table_record(%Table{} = table) do
    table
    |> Table.changeset_delete(%{deleted_at: NaiveDateTime.utc_now()})
    |> Repo.update()
    |> add_relations()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking table changes.

  ## Examples

      iex> change_table_record(table)
      %Ecto.Changeset{data: %Table{}}

  """
  def change_table_record(%Table{} = table, attrs \\ %{}) do
    Table.changeset(table, attrs)
  end
end
