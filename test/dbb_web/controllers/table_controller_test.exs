defmodule DbbWeb.TableControllerTest do
  use DbbWeb.ConnCase

  import Dbb.ContentFixtures

  alias Dbb.Content.Table

  @create_attrs %{
    data: %{},
    deleted_at: ~N[2023-04-17 23:57:00],
    reference: "7488a646-e31f-11e4-aace-600308960662",
    schema: "some schema"
  }
  @update_attrs %{
    data: %{},
    deleted_at: ~N[2023-04-18 23:57:00],
    reference: "7488a646-e31f-11e4-aace-600308960668",
    schema: "some updated schema"
  }
  @invalid_attrs %{data: nil, deleted_at: nil, reference: nil, schema: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all table", %{conn: conn} do
      conn = get(conn, ~p"/api/table")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create table" do
    test "renders table when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/table", table: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/table/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{},
               "deleted_at" => "2023-04-17T23:57:00",
               "reference" => "7488a646-e31f-11e4-aace-600308960662",
               "schema" => "some schema"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/table", table: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update table" do
    setup [:create_table]

    test "renders table when data is valid", %{conn: conn, table: %Table{id: id} = table} do
      conn = put(conn, ~p"/api/table/#{table}", table: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/table/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{},
               "deleted_at" => "2023-04-18T23:57:00",
               "reference" => "7488a646-e31f-11e4-aace-600308960668",
               "schema" => "some updated schema"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, table: table} do
      conn = put(conn, ~p"/api/table/#{table}", table: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete table" do
    setup [:create_table]

    test "deletes chosen table", %{conn: conn, table: table} do
      conn = delete(conn, ~p"/api/table/#{table}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/table/#{table}")
      end
    end
  end

  defp create_table(_) do
    table = table_fixture()
    %{table: table}
  end
end
