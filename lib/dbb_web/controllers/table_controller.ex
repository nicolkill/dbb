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

    table = Content.list_table(schema, query, page, count)
    TableHandler.hooks(:index, schema, params)
    render(conn, :index, table: table, page: page, count: count)
  end

  def show(conn, params) do
    {schema, id, _} = TableHandler.validate_schema(params)

    table = Content.get_table!(schema, id)
    TableHandler.hooks(:show, schema, params, table)
    render(conn, :show, table: table)
  end

  def create(conn, params) do
    with {schema, _, {:ok, data}} <- TableHandler.validate_schema(params),
         {:ok, %Table{} = table} <- Content.create_table(schema, data) do
      TableHandler.hooks(:create, schema, params, table)

      conn
      |> put_status(201)
      |> render(:show, table: table)
    end
  end

  def update(conn, params) do
    with {schema, id, {:ok, data}} <- TableHandler.validate_schema(params),
         table <- Content.get_table!(schema, id),
         {:ok, %Table{} = table} <- Content.update_table(table, data) do
      TableHandler.hooks(:update, schema, params, table)
      render(conn, :show, table: table)
    end
  end

  def delete(conn, params) do
    {schema, id, _} = TableHandler.validate_schema(params)
    table = Content.get_table!(schema, id)

    with {:ok, %Table{}} <- Content.delete_table(table) do
      TableHandler.hooks(:delete, schema, params, table)
      send_resp(conn, :no_content, "")
    end
  end
end
