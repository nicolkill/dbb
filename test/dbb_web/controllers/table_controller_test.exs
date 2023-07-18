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

  describe "index with users" do
    setup [:create_users]

    test "lists all users", %{conn: conn} do
      conn = get(conn, "/api/v1/users?page=1&count=2")
      assert [%{
               "data" => %{"name" => "mike"},
               "schema" => "users"
             }] = json_response(conn, 200)["data"]
    end

    test "lists all users using null filter", %{conn: conn} do
      conn = get(conn, "/api/v1/users?q=age:null")
      assert [
               %{
                 "data" => %{"name" => "mike"},
                 "schema" => "users"
               },
             ] = json_response(conn, 200)["data"]
    end

    test "lists all users using not null filter", %{conn: conn} do
      conn = get(conn, "/api/v1/users?q=age:not_null")
      assert [
               %{
                 "data" => %{"name" => "jhon"},
                 "schema" => "users"
               },
               %{
                 "data" => %{"name" => "jim"},
                 "schema" => "users"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "lists all users that starts with the letter 'j'", %{conn: conn} do
      conn = get(conn, "/api/v1/users?q=name:j")
      assert [
               %{
                 "data" => %{"name" => "jhon"},
                 "schema" => "users"
               },
               %{
                 "data" => %{"name" => "jim"},
                 "schema" => "users"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "lists all users that starts with the word 'mike'", %{conn: conn} do
      conn = get(conn, "/api/v1/users?q=name:mike")
      assert [
               %{
                 "data" => %{"name" => "mike"},
                 "schema" => "users"
               }
             ] = json_response(conn, 200)["data"]
    end
  end

  describe "create users" do
    test "renders users when data is valid", %{conn: conn} do
      Tesla.Mock.mock(fn
        %{method: :post, url: "https://someurl.test/webhook"} ->
          %Tesla.Env{status: 200, url: "https://someurl.test/webhook", body: %{"status" => "Ok"}}
      end)

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

    test "renders users when data is valid", %{conn: conn, users: users} do
      %Table{id: id} = user = Enum.at(users, 0)

      conn = put(conn, ~p"/api/v1/users/#{user}", data: @update_attrs)
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
      user = Enum.at(users, 0)
      conn = put(conn, ~p"/api/v1/users/#{user}", data: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete element" do
    setup [:create_users]

    test "deletes chosen user", %{conn: conn, users: users} do
      user = Enum.at(users, 0)
      conn = delete(conn, ~p"/api/v1/users/#{user}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/v1/users/#{user}")
      end
    end
  end

  defp create_users(_) do
    user1 = users_fixture(%{data: %{name: "jhon", age: 20}})
    user2 = users_fixture(%{data: %{name: "jim", age: 22}})
    user3 = users_fixture(%{data: %{name: "mike"}})

    %{users: [user1, user2, user3]}
  end
end
