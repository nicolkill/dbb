defmodule Dbb.TableApi do
  alias Dbb.TableHandler
  alias Dbb.Content
  alias Dbb.Content.Table
  alias Dbb.Utils

  @type index_r :: %{
          schema: String.t(),
          page: integer(),
          count: integer(),
          q: String.t()
        }

  @type show_delete_r :: %{
          schema: String.t(),
          id: String.t()
        }

  @type create_r :: %{
          schema: String.t(),
          data: map()
        }

  @type update_r :: %{
          schema: String.t(),
          data: map(),
          id: String.t()
        }

  @type index_res :: %{
          table: [Table.t()],
          page: integer(),
          count: integer(),
          relations: [String.t()]
        }

  @type upsert_res :: {:ok, Table.t()} | {:error, any()} | {any(), any(), any()}

  @doc """
  - schema - mandatory
  - page
  - count
  - q

  Possible query options

  - your_field:not_null - to verify is not null
  - your_field:null     - to verify is null
  - your_field:anything - its inside text (in any place, case sensitive)

  %{
    schema: "your_table_name",
    page: 1,
    count: 10,
    q: "your_field:possible_value"
  }
  |> Dbb.TableApi.index()
  """
  @spec index(index_r()) :: index_res()
  def index(params, call_hook? \\ false) do
    params = Utils.purify_params(params)
    {schema, _, _} = TableHandler.validate_schema(params)
    {page, count} = TableHandler.pagination(params)
    query = TableHandler.search(params)
    relations = TableHandler.relations(params)

    table_record = Content.list_table_records(schema, query, page, count, relations)

    if call_hook?,
      do: TableHandler.hooks(:index, schema, params)

    %{
      table: table_record,
      page: page,
      count: length(table_record),
      relations: relations
    }
  end

  @doc """
  - schema - mandatory
  - id     - mandatory

  %{
    schema: "your_table_name",
    id: "99cc764d-afa9-4f36-9f56-33d3ce970b11"
  }
  |> Dbb.TableApi.show()
  """
  @spec show(show_delete_r()) :: {:ok, Table.t()}
  def show(params, call_hook? \\ false) do
    params = Utils.purify_params(params)
    {schema, id, _} = TableHandler.validate_schema(params)
    relations = TableHandler.relations(params)

    table_record = Content.get_table_record!(schema, id, relations)

    if call_hook?,
      do: TableHandler.hooks(:show, schema, params, table_record)

    {:ok, table_record}
  end

  @doc """
  - schema - mandatory
  - data   - mandatory

  %{
    schema: "your_table_name",
    data: %{
      some_field: "some_value"
    }
  }
  |> Dbb.TableApi.create()
  """
  @spec create(create_r()) :: upsert_res()
  def create(params, call_hook? \\ false) do
    params = Utils.purify_params(params)

    with {schema, _, {:ok, data}} <- TableHandler.validate_schema(params),
         {:ok, %Table{} = table_record} <- Content.create_table_record(schema, data) do
      if call_hook?,
        do: TableHandler.hooks(:create, schema, params, table_record)

      {:ok, table_record}
    end
  end

  @doc """
  - schema - mandatory
  - id     - mandatory
  - data   - mandatory

  %{
    schema: "your_table_name",
    id: "99cc764d-afa9-4f36-9f56-33d3ce970b11",
    data: %{
      some_field: "some_value"
    }
  }
  |> Dbb.TableApi.create()
  """
  @spec update(update_r()) :: upsert_res()
  def update(params, call_hook? \\ false) do
    params = Utils.purify_params(params)

    with {schema, id, {:ok, data}} <- TableHandler.validate_schema(params),
         table_record <- Content.get_table_record!(schema, id),
         {:ok, %Table{} = table_record} <- Content.update_table_record(table_record, data) do
      if call_hook?,
        do: TableHandler.hooks(:update, schema, params, table_record)

      {:ok, table_record}
    end
  end

  @doc """
  - schema - mandatory
  - id     - mandatory

  %{
    schema: "your_table_name",
    id: "99cc764d-afa9-4f36-9f56-33d3ce970b11"
  }
  |> Dbb.TableApi.show()
  """
  @spec delete(show_delete_r()) :: boolean() | {:error, any()}
  def delete(params, call_hook? \\ false) do
    {schema, id, _} = TableHandler.validate_schema(params)
    table_record = Content.get_table_record!(schema, id)

    with {:ok, %Table{}} <- Content.delete_table_record(table_record) do
      if call_hook?,
        do: TableHandler.hooks(:delete, schema, params, table_record)

      true
    end
  end
end
