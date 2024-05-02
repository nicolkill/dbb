defmodule DbbWeb.TableControllerTest do
  use DbbWeb.ConnCase

  import Dbb.ContentFixtures

  alias Dbb.Schema
  alias Dbb.Content.Table

  @create_attrs %{
    age: 20,
    male: true,
    name: "Pancracio",
    birth: "2023-05-02 00:00:00",
    flags: ["flag-1", "flag-2"]
  }
  @update_attrs %{
    male: true,
    name: "Pancracio Jr",
    flags: ["flag-3"]
  }
  @invalid_attrs %{
    male: 20,
    flags: [false]
  }

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

      assert [
               %{
                 "data" => %{"name" => "mike"},
                 "schema" => "users"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "lists all users using null filter", %{conn: conn} do
      conn = get(conn, "/api/v1/users?q=age:null")

      assert [
               %{
                 "data" => %{"name" => "mike"},
                 "schema" => "users"
               }
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
        %{method: :post, url: "https://someurl.test/webhook"} = env ->
          assert [{"custom_header", "header value"} | _] = env.headers
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
                 "name" => "Pancracio",
                 "flags" => ["flag-1", "flag-2"],
                 "sku" => sku
               },
               "reference" => nil,
               "schema" => "users"
             } = json_response(conn, 200)["data"]

      assert [_, _, _, _] = String.split(sku, "-")
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

    test "renders users when data is valid", %{conn: conn, users: [user | _]} do
      %Table{id: id} = user

      conn = put(conn, ~p"/api/v1/users/#{user}", data: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/v1/users/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{
                 "male" => true,
                 "name" => "Pancracio Jr",
                 "flags" => ["flag-3"]
               },
               "reference" => nil,
               "schema" => "users"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, users: users} do
      user = Enum.at(users, 0)
      conn = put(conn, ~p"/api/v1/users/#{user}", data: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "products and orders relations" do
    setup [:create_users, :create_product]

    test "relates product with user", %{conn: conn, users: [user | _], product: product} do
      attrs = %{
        user_id: user.id,
        estimated_delivery_time: "2024-04-24 00:00:00"
      }

      conn = post(conn, ~p"/api/v1/orders", data: attrs)
      assert %{"id" => order_id} = json_response(conn, 201)["data"]

      attrs = %{
        "order_id" => order_id,
        "product_id" => product.id
      }

      conn = post(conn, ~p"/api/v1/order_product", data: attrs)
      assert %{"id" => _} = json_response(conn, 201)["data"]
    end

    test "creates table record without relation", %{conn: conn} do
      attrs = %{
        estimated_delivery_time: "2024-04-24 00:00:00"
      }

      conn = post(conn, ~p"/api/v1/orders", data: attrs)
      assert %{"id" => _} = json_response(conn, 201)["data"]
    end

    test "fails on relation with not existing relation", %{conn: conn} do
      attrs = %{
        # not exist
        user_id: "78b6130b-1eea-4647-9769-1f96a4b32d93",
        estimated_delivery_time: "2024-04-24 00:00:00"
      }

      conn = post(conn, ~p"/api/v1/orders", data: attrs)
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
    user1 = users_fixture(%{"name" => "jhon", "age" => 20})
    user2 = users_fixture(%{"name" => "jim", "age" => 22})
    user3 = users_fixture(%{"name" => "mike"})

    %{users: [user1, user2, user3]}
  end

  #  defp create_order(%{users: [user | _], product: product}) do
  #    order =
  #      orders_fixture(%{
  #        "user_id" => user.id,
  #        "estimated_delivery_time" => "2024-04-24 00:00:00"
  #      })
  #
  #    relation =
  #      order_product_fixture(%{
  #        "order_id" => order.id,
  #        "product_id" => product.id
  #      })
  #
  #    %{order: order, relation: relation}
  #  end

  defp create_product(_) do
    product =
      products_fixture(%{
        "name" => "phone case",
        "description" => "this it's a phone case to any type of phone"
      })

    %{product: product}
  end
end
