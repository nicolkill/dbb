defmodule DbbWeb.TableControllerTest do
  use DbbWeb.ConnCase

  import Dbb.ContentFixtures

  alias Dbb.Schema
  alias Dbb.Content.Table

  @create_attrs %{
    data: %{
      age: 20,
      male: true,
      name: "Pancracio",
      birth: "2023-05-02 00:00:00"
    },
    reference: "7488a646-e31f-11e4-aace-600308960662",
    schema: "users"
  }
  @update_attrs %{
    data: %{
      male: true,
      name: "Pancracio Jr"
    },
    reference: "7488a646-e31f-11e4-aace-600308960668"
  }
  @invalid_attrs %{data: nil, deleted_at: nil, reference: nil, schema: nil}

  setup %{conn: conn} do
    Schema.load_config()

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, "/api/v1/users")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create users" do
    test "renders users when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/users", data: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/users/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{
                 "age" => 20,
                 "birth" => "2023-05-02 00:00:00",
                 "male" => true,
                 "name" => "Pancracio"
               },
               "reference" => "7488a646-e31f-11e4-aace-600308960662",
               "schema" => "users"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/users", data: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "calls to not existing schema" do
    test "creates a record on not existing schema", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/unknown", data: @create_attrs)
      assert %{"message" => "not found body"} = json_response(conn, 422)

    end
  end

  describe "update user" do
    setup [:create_users]

    test "renders users when data is valid", %{conn: conn, users: %Table{id: id} = users} do
      conn = put(conn, ~p"/api/v1/users/#{users}", data: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/v1/users/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{
                 "male" => true,
                 "name" => "Pancracio Jr"
               },
               "reference" => "7488a646-e31f-11e4-aace-600308960668",
               "schema" => "users"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, users: users} do
      conn = put(conn, ~p"/api/v1/users/#{users}", data: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete element" do
    setup [:create_users]

    test "deletes chosen user", %{conn: conn, users: users} do
      conn = delete(conn, ~p"/api/v1/users/#{users}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/v1/users/#{users}")
      end
    end
  end

  defp create_users(_) do
    user = users_fixture()
    %{users: user}
  end
end
