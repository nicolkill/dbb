defmodule DbbWeb.TableControllerTest do
  use DbbWeb.ConnCase

  import Dbb.ContentFixtures

  alias Dbb.Schema
  alias Dbb.Content.Table

  @user_create_attrs %{
    age: 20,
    male: true,
    name: "Pancracio",
    birth: "2023-05-02 00:00:00",
    flags: ["flag-1", "flag-2"]
  }
  @user_update_attrs %{
    male: true,
    name: "Pancracio Jr",
    flags: ["flag-3"]
  }
  @user_invalid_attrs %{
    male: 20,
    flags: [false]
  }

  @product_create_attrs %{
    name: "macbook pro",
    description: "this it's a very expensive laptop"
  }

  setup %{conn: conn} do
    Schema.load_config()

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, "/api/v1/user_accounts")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "index with users" do
    setup [:create_users, :create_product, :create_order]

    test "lists all users", %{conn: conn} do
      conn = get(conn, "/api/v1/user_accounts?page=1&count=2")

      assert [
               %{
                 "data" => %{"name" => "mike"},
                 "schema" => "user_accounts"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "lists all users using null filter", %{conn: conn} do
      conn = get(conn, "/api/v1/user_accounts?q=age:null")

      assert [
               %{
                 "data" => %{"name" => "mike"},
                 "schema" => "user_accounts"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "lists all users using not null filter", %{conn: conn} do
      conn = get(conn, "/api/v1/user_accounts?q=age:not_null")

      assert [
               %{
                 "data" => %{"name" => "John"},
                 "schema" => "user_accounts"
               },
               %{
                 "data" => %{"name" => "Jim"},
                 "schema" => "user_accounts"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "lists all users that starts with the letter 'j'", %{conn: conn} do
      conn = get(conn, "/api/v1/user_accounts?q=name:j")

      assert [
               %{
                 "data" => %{"name" => "John"},
                 "schema" => "user_accounts"
               },
               %{
                 "data" => %{"name" => "Jim"},
                 "schema" => "user_accounts"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "lists all users that starts with the word 'mike'", %{conn: conn} do
      conn = get(conn, "/api/v1/user_accounts?q=name:mike")

      assert [
               %{
                 "data" => %{"name" => "mike"},
                 "schema" => "user_accounts"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "lists all users that starts with the word 'john' and preload relations", %{conn: conn} do
      conn = get(conn, "/api/v1/user_accounts?q=name:john")

      assert [
               %{
                 "data" => %{
                   "name" => "John"
                 },
                 "id" => user_id,
                 "schema" => "user_accounts"
               }
             ] = json_response(conn, 200)["data"]

      conn = get(conn, "/api/v1/orders?q=user_id:#{user_id}&relations=user")

      assert [
               %{
                 "data" => %{
                   "user_id" => ^user_id
                 },
                 "relations" => %{
                   "user_accounts" => %{
                     "data" => %{
                       "name" => "John"
                     },
                     "id" => ^user_id
                   }
                 },
                 "schema" => "orders"
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

      conn = post(conn, ~p"/api/v1/user_accounts", data: @user_create_attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/user_accounts/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{
                 "age" => 20,
                 "birth" => "2023-05-02 00:00:00",
                 "male" => true,
                 "name" => "Pancracio",
                 "flags" => ["flag-1", "flag-2"]
               },
               "schema" => "user_accounts"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/user_accounts", data: @user_invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "create product" do
    test "renders users when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/products", data: @product_create_attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/products/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{
                 "name" => "macbook pro",
                 "description" => "this it's a very expensive laptop",
                 "sku" => sku
               },
               "schema" => "products"
             } = json_response(conn, 200)["data"]

      assert [_, _, _, _] = String.split(sku, "-")
    end
  end

  describe "calls to not existing schema" do
    test "creates a record on not existing schema", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/unknown", data: @user_create_attrs)
      assert %{"message" => "not found body"} = json_response(conn, 422)
    end
  end

  describe "update user" do
    setup [:create_users]

    test "renders users when data is valid", %{conn: conn, users: [user | _]} do
      %Table{id: id} = user

      conn = put(conn, ~p"/api/v1/user_accounts/#{user}", data: @user_update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/v1/user_accounts/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{
                 "male" => true,
                 "name" => "Pancracio Jr",
                 "flags" => ["flag-3"]
               },
               "schema" => "user_accounts"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, users: users} do
      user = Enum.at(users, 0)
      conn = put(conn, ~p"/api/v1/user_accounts/#{user}", data: @user_invalid_attrs)

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

    test "fails create table record without relation because it's mandatory", %{conn: conn} do
      attrs = %{
        estimated_delivery_time: "2024-04-24 00:00:00"
      }

      conn = post(conn, ~p"/api/v1/orders", data: attrs)
      assert json_response(conn, 422)["errors"] != %{}
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

  describe "profiles with map fields" do
    @valid_profile_attrs %{
      "name" => "John Doe",
      "bio" => "Software developer",
      "settings" => %{
        "theme" => "dark",
        "notifications" => true,
        "language" => "en"
      },
      "metadata" => %{
        "created_by" => "admin",
        "version" => 1,
        "tags" => ["vip", "early-adopter"]
      },
      "tags" => ["developer", "admin"]
    }

    @profile_update_attrs %{
      "settings" => %{
        "theme" => "light",
        "notifications" => false
      }
    }

    test "creates profile with valid map fields", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/profiles", data: @valid_profile_attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/profiles/#{id}")

      assert %{
               "id" => ^id,
               "data" => %{
                 "name" => "John Doe",
                 "bio" => "Software developer",
                 "settings" => %{
                   "theme" => "dark",
                   "notifications" => true,
                   "language" => "en"
                 },
                 "metadata" => %{
                   "created_by" => "admin",
                   "version" => 1,
                   "tags" => ["vip", "early-adopter"]
                 },
                 "tags" => ["developer", "admin"]
               },
               "schema" => "profiles"
             } = json_response(conn, 200)["data"]
    end

    test "creates profile with empty map", %{conn: conn} do
      attrs = %{
        "name" => "Empty Maps User",
        "settings" => %{},
        "metadata" => %{}
      }

      conn = post(conn, ~p"/api/v1/profiles", data: attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/profiles/#{id}")

      assert %{
               "data" => %{
                 "settings" => %{},
                 "metadata" => %{}
               }
             } = json_response(conn, 200)["data"]
    end

    test "creates profile with deeply nested map", %{conn: conn} do
      attrs = %{
        "name" => "Nested User",
        "settings" => %{
          "theme" => "dark",
          "advanced" => %{
            "cache" => %{
              "enabled" => true,
              "ttl" => 3600
            },
            "features" => ["beta", "experimental"]
          }
        }
      }

      conn = post(conn, ~p"/api/v1/profiles", data: attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/profiles/#{id}")

      assert %{
               "data" => %{
                 "settings" => %{
                   "theme" => "dark",
                   "advanced" => %{
                     "cache" => %{
                       "enabled" => true,
                       "ttl" => 3600
                     },
                     "features" => ["beta", "experimental"]
                   }
                 }
               }
             } = json_response(conn, 200)["data"]
    end

    test "renders error when settings is not a map", %{conn: conn} do
      conn =
        post(conn, ~p"/api/v1/profiles",
          data: %{
            "name" => "Invalid User",
            "settings" => "not a map",
            "metadata" => ["not", "a", "map"]
          }
        )

      assert %{"message" => "not valid body"} = json_response(conn, 422)
    end

    test "renders error when metadata is array instead of map", %{conn: conn} do
      attrs = %{
        "name" => "Bad Metadata",
        "metadata" => ["item1", "item2"]
      }

      conn = post(conn, ~p"/api/v1/profiles", data: attrs)

      assert %{"message" => "not valid body"} = json_response(conn, 422)
    end

    test "renders error when map field is null", %{conn: conn} do
      attrs = %{
        "name" => "Null Map User",
        "settings" => nil
      }

      conn = post(conn, ~p"/api/v1/profiles", data: attrs)

      assert %{"message" => "not valid body"} = json_response(conn, 422)
    end

    test "renders error when map field is number", %{conn: conn} do
      attrs = %{
        "name" => "Number Map User",
        "settings" => 12345
      }

      conn = post(conn, ~p"/api/v1/profiles", data: attrs)

      assert %{"message" => "not valid body"} = json_response(conn, 422)
    end

    test "renders error when map field is boolean", %{conn: conn} do
      attrs = %{
        "name" => "Boolean Map User",
        "metadata" => true
      }

      conn = post(conn, ~p"/api/v1/profiles", data: attrs)

      assert %{"message" => "not valid body"} = json_response(conn, 422)
    end

    test "updates profile map field", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/profiles", data: @valid_profile_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = put(conn, ~p"/api/v1/profiles/#{id}", data: @profile_update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/v1/profiles/#{id}")

      assert %{
               "data" => %{
                 "settings" => %{
                   "theme" => "light",
                   "notifications" => false
                 }
               }
             } = json_response(conn, 200)["data"]
    end

    test "lists all profiles", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/profiles", data: @valid_profile_attrs)
      assert %{"id" => _id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/profiles")

      assert [
               %{
                 "data" => %{
                   "name" => "John Doe",
                   "settings" => %{
                     "theme" => "dark"
                   }
                 },
                 "schema" => "profiles"
               }
             ] = json_response(conn, 200)["data"]
    end

    test "filters profiles by nested map content", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/profiles", data: @valid_profile_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/profiles?q=name:John")

      assert [
               %{
                 "data" => %{"name" => "John Doe"},
                 "id" => ^id
               }
             ] = json_response(conn, 200)["data"]
    end
  end

  describe "delete element" do
    setup [:create_users]

    test "deletes chosen user", %{conn: conn, users: users} do
      user = Enum.at(users, 0)
      conn = delete(conn, ~p"/api/v1/user_accounts/#{user}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/v1/user_accounts/#{user}")
      end
    end
  end

  defp create_users(_) do
    user1 = users_fixture(%{"name" => "John", "age" => 20})
    user2 = users_fixture(%{"name" => "Jim", "age" => 22})
    user3 = users_fixture(%{"name" => "mike"})

    %{users: [user1, user2, user3]}
  end

  defp create_order(%{users: [user | _], product: product}) do
    order =
      orders_fixture(%{
        "user_id" => user.id,
        "estimated_delivery_time" => "2024-04-24 00:00:00"
      })

    relation =
      order_product_fixture(%{
        "order_id" => order.id,
        "product_id" => product.id
      })

    %{order: order, relation: relation}
  end

  defp create_product(_) do
    product =
      products_fixture(%{
        "name" => "phone case",
        "description" => "this it's a phone case to any type of phone"
      })

    %{product: product}
  end
end
