defmodule DbbWeb.TableController do
  use DbbWeb, :controller

  alias Dbb.TableApi

  action_fallback DbbWeb.FallbackController

  def index(conn, params) do
    %{
      table: table_data,
      page: page,
      count: count,
      relations: relations
    } = TableApi.index(params)

    render(conn, :index, table: table_data, page: page, count: count, relations: relations)
  end

  def show(conn, params) do
    {:ok, table_record} = TableApi.show(params)
    render(conn, :show, table: table_record)
  end

  def create(conn, params) do
    with {:ok, table_record} <- TableApi.create(params) do
      conn
      |> put_status(201)
      |> render(:show, table: table_record)
    end
  end

  def update(conn, params) do
    with {:ok, table_record} <- TableApi.update(params) do
      render(conn, :show, table: table_record)
    end
  end

  def delete(conn, params) do
    with true <- TableApi.delete(params) do
      send_resp(conn, :no_content, "")
    end
  end
end
