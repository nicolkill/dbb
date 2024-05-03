defmodule DbbWeb.TableController do
  use DbbWeb, :controller

  alias Dbb.TableHandler
  alias Dbb.Content
  alias Dbb.Content.Table

  action_fallback DbbWeb.FallbackController

  def index(conn, params) do
    {schema, _, _} = TableHandler.validate_schema(params)
    {page, count} = TableHandler.pagination(params)
    query = TableHandler.search(params)
    relations = TableHandler.relations(params)

    table_record = Content.list_table_records(schema, query, page, count, relations)
    TableHandler.hooks(:index, schema, params)
    render(conn, :index, table: table_record, page: page, count: count, relations: relations)
  end

  def show(conn, params) do
    {schema, id, _} = TableHandler.validate_schema(params)
    relations = TableHandler.relations(params)

    table_record = Content.get_table_record!(schema, id, relations)
    TableHandler.hooks(:show, schema, params, table_record)
    render(conn, :show, table: table_record)
  end

  def create(conn, params) do
    with {schema, _, {:ok, data}} <- TableHandler.validate_schema(params),
         {:ok, %Table{} = table_record} <- Content.create_table_record(schema, data) do
      TableHandler.hooks(:create, schema, params, table_record)

      conn
      |> put_status(201)
      |> render(:show, table: table_record)
    end
  end

  def update(conn, params) do
    with {schema, id, {:ok, data}} <- TableHandler.validate_schema(params),
         table_record <- Content.get_table_record!(schema, id),
         {:ok, %Table{} = table_record} <- Content.update_table_record(table_record, data) do
      TableHandler.hooks(:update, schema, params, table_record)
      render(conn, :show, table: table_record)
    end
  end

  def delete(conn, params) do
    {schema, id, _} = TableHandler.validate_schema(params)
    table_record = Content.get_table_record!(schema, id)

    with {:ok, %Table{}} <- Content.delete_table_record(table_record) do
      TableHandler.hooks(:delete, schema, params, table_record)
      send_resp(conn, :no_content, "")
    end
  end
end
