defmodule DbbWeb.TableController do
  use DbbWeb, :controller

  alias Dbb.Content
  alias Dbb.Content.Table

  action_fallback DbbWeb.FallbackController

  def index(conn, _params) do
    table = Content.list_table()
    render(conn, :index, table: table)
  end

  def show(conn, %{"id" => id}) do
    table = Content.get_table!(id)
    render(conn, :show, table: table)
  end

  def create(conn, %{"table" => table_params}) do
    with {:ok, %Table{} = table} <- Content.create_table(table_params) do
      conn
      |> put_status(201)
      |> put_resp_header("location", ~p"/api/table/#{table}")
      |> render(:show, table: table)
    end
  end

  def update(conn, %{"id" => id, "table" => table_params}) do
    table = Content.get_table!(id)

    with {:ok, %Table{} = table} <- Content.update_table(table, table_params) do
      render(conn, :show, table: table)
    end
  end

  def delete(conn, %{"id" => id}) do
    table = Content.get_table!(id)

    with {:ok, %Table{}} <- Content.delete_table(table) do
      send_resp(conn, :no_content, "")
    end
  end
end
