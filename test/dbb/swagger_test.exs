defmodule Dbb.SwaggerTest do
  use ExUnit.Case, async: false

  @config_path Path.expand("../../prod_test.json", __DIR__)

  defp load_config do
    @config_path
    |> File.read!()
    |> Jason.decode!()
  end

  defp capitalize(name) do
    name
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("")
  end

  describe "generate_swagger/1" do
    setup do
      config = load_config()
      %{config: config}
    end

    test "generates valid JSON structure", %{config: config} do
      _ = Dbb.Swagger.generate_swagger(config)
      # Function writes to file and returns :ok, so we read the file
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      # Validate top-level structure
      assert is_map(generated_json)
      assert generated_json["swagger"] == "2.0"
      assert generated_json["info"] == %{"version" => "1.0", "title" => "dbb"}
      assert is_map(generated_json["paths"])
      assert is_map(generated_json["definitions"])
    end

    test "generates paths for all schemas", %{config: config} do
      Dbb.Swagger.generate_swagger(config)
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      paths = generated_json["paths"]

      # Check that all schemas have CRUD endpoints
      for schema <- config["schemas"] do
        name = schema["name"]
        assert Map.has_key?(paths, "/api/v1/#{name}"), "Missing index path for #{name}"
        assert Map.has_key?(paths, "/api/v1/#{name}/{id}"), "Missing item path for #{name}"

        # Check CRUD operations
        assert Map.has_key?(paths["/api/v1/#{name}"], "get"), "Missing GET for #{name}"
        assert Map.has_key?(paths["/api/v1/#{name}"], "post"), "Missing POST for #{name}"
        assert Map.has_key?(paths["/api/v1/#{name}/{id}"], "get"), "Missing GET by ID for #{name}"
        assert Map.has_key?(paths["/api/v1/#{name}/{id}"], "put"), "Missing PUT for #{name}"
        assert Map.has_key?(paths["/api/v1/#{name}/{id}"], "delete"), "Missing DELETE for #{name}"
      end
    end

    test "generates definitions for all schemas", %{config: config} do
      Dbb.Swagger.generate_swagger(config)
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      definitions = generated_json["definitions"]

      # Check that all schemas have required definition types
      for schema <- config["schemas"] do
        cap_name = capitalize(schema["name"])

        assert Map.has_key?(definitions, cap_name),
               "Missing base definition for #{cap_name}"

        assert Map.has_key?(definitions, "#{cap_name}Request"),
               "Missing Request definition for #{cap_name}"

        assert Map.has_key?(definitions, "#{cap_name}Response"),
               "Missing Response definition for #{cap_name}"

        assert Map.has_key?(definitions, "#{cap_name}ResponseMulti"),
               "Missing ResponseMulti definition for #{cap_name}"
      end
    end

    test "generates correct field types in definitions", %{config: config} do
      Dbb.Swagger.generate_swagger(config)
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      definitions = generated_json["definitions"]

      # Test user_accounts fields
      user_accounts_def = definitions["UserAccounts"]
      assert user_accounts_def["properties"]["email"]["type"] == "string"
      assert user_accounts_def["properties"]["name"]["type"] == "string"
      assert user_accounts_def["properties"]["age"]["type"] == "number"
      assert user_accounts_def["properties"]["male"]["type"] == "boolean"
      assert user_accounts_def["properties"]["birth"]["type"] == "string"
      assert user_accounts_def["properties"]["birth"]["format"] == "date-time"
      assert user_accounts_def["properties"]["flags"]["type"] == "array"

      # Test products fields
      products_def = definitions["Products"]
      assert products_def["properties"]["name"]["type"] == "string"
      assert products_def["properties"]["description"]["type"] == "string"
      assert products_def["properties"]["sku"]["type"] == "string"

      # Test profiles with map type
      profiles_def = definitions["Profiles"]
      assert profiles_def["properties"]["name"]["type"] == "string"
      assert profiles_def["properties"]["bio"]["type"] == "string"
      assert profiles_def["properties"]["tags"]["type"] == "array"
    end

    test "generates correct response structure", %{config: config} do
      Dbb.Swagger.generate_swagger(config)
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      definitions = generated_json["definitions"]

      # Check response structure has required fields
      for schema <- config["schemas"] do
        cap_name = capitalize(schema["name"])
        response_def = definitions["#{cap_name}Response"]["properties"]["data"]["properties"]

        assert Map.has_key?(response_def, "schema")
        assert Map.has_key?(response_def, "id")
        assert Map.has_key?(response_def, "reference")
        assert Map.has_key?(response_def, "inserted_at")
        assert Map.has_key?(response_def, "updated_at")
        assert Map.has_key?(response_def, "data")

        # Check field types
        assert response_def["schema"]["type"] == "string"
        assert response_def["id"]["type"] == "string"
        assert response_def["reference"]["type"] == "string"
        assert response_def["inserted_at"]["type"] == "string"
        assert response_def["inserted_at"]["format"] == "date-time"
        assert response_def["updated_at"]["type"] == "string"
        assert response_def["updated_at"]["format"] == "date-time"
      end
    end

    test "generates correct multi-response structure", %{config: config} do
      Dbb.Swagger.generate_swagger(config)
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      definitions = generated_json["definitions"]

      # Check multi-response structure
      for schema <- config["schemas"] do
        cap_name = capitalize(schema["name"])
        multi_def = definitions["#{cap_name}ResponseMulti"]

        assert multi_def["properties"]["page"]["type"] == "integer"
        assert multi_def["properties"]["count"]["type"] == "integer"
        assert multi_def["properties"]["data"]["type"] == "array"

        assert multi_def["properties"]["data"]["items"]["$ref"] ==
                 "#/definitions/#{cap_name}Response"
      end
    end

    test "generates valid Swagger 2.0 format", %{config: config} do
      Dbb.Swagger.generate_swagger(config)
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      # Validate Swagger 2.0 required fields
      assert generated_json["swagger"] == "2.0"
      assert is_map(generated_json["info"])
      assert generated_json["info"]["version"]
      assert generated_json["info"]["title"]
      assert is_map(generated_json["paths"])
      assert is_map(generated_json["definitions"])

      # Validate paths structure
      for {_path, operations} <- generated_json["paths"] do
        assert is_map(operations)

        for {method, operation} <- operations do
          assert method in ["get", "post", "put", "delete"]
          assert operation["description"]
          assert operation["summary"]
          assert operation["tags"]
          assert is_list(operation["tags"])
          assert operation["responses"]
          assert is_map(operation["responses"])
        end
      end

      # Validate definitions structure
      for {_name, definition} <- generated_json["definitions"] do
        assert definition["title"]
        assert definition["type"] == "object"
        assert definition["description"]
        assert definition["properties"]
        assert is_map(definition["properties"])
      end
    end

    test "generates examples in responses", %{config: config} do
      Dbb.Swagger.generate_swagger(config)
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      # Check that GET all has examples
      user_accounts_get = generated_json["paths"]["/api/v1/user_accounts"]["get"]
      assert user_accounts_get["responses"]["200"]["examples"]
      assert user_accounts_get["responses"]["200"]["examples"]["application/json"]

      # Check that GET one has examples
      user_accounts_get_one = generated_json["paths"]["/api/v1/user_accounts/{id}"]["get"]
      assert user_accounts_get_one["responses"]["200"]["examples"]
      assert user_accounts_get_one["responses"]["200"]["examples"]["application/json"]

      # Check that POST has examples
      user_accounts_post = generated_json["paths"]["/api/v1/user_accounts"]["post"]
      assert user_accounts_post["responses"]["201"]["examples"]
      assert user_accounts_post["responses"]["201"]["examples"]["application/json"]

      # Check that PUT has examples
      user_accounts_put = generated_json["paths"]["/api/v1/user_accounts/{id}"]["put"]
      assert user_accounts_put["responses"]["200"]["examples"]
      assert user_accounts_put["responses"]["200"]["examples"]["application/json"]
    end

    test "generates parameters correctly", %{config: config} do
      Dbb.Swagger.generate_swagger(config)
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      # Check path parameter for item operations
      for schema <- config["schemas"] do
        name = schema["name"]
        get_one = generated_json["paths"]["/api/v1/#{name}/{id}"]["get"]

        assert get_one["parameters"]
        assert length(get_one["parameters"]) == 1
        path_param = get_one["parameters"] |> Enum.at(0)
        assert path_param["name"] == "id"
        assert path_param["in"] == "path"
        assert path_param["required"] == true
        assert path_param["type"] == "string"
      end

      # Check body parameter for create/update operations
      for schema <- config["schemas"] do
        name = schema["name"]
        post = generated_json["paths"]["/api/v1/#{name}"]["post"]
        put = generated_json["paths"]["/api/v1/#{name}/{id}"]["put"]

        assert post["parameters"]
        assert length(post["parameters"]) == 1
        body_param = post["parameters"] |> Enum.at(0)
        assert body_param["in"] == "body"
        assert body_param["schema"]["$ref"]

        assert put["parameters"]
        assert length(put["parameters"]) == 2
        assert Enum.find(put["parameters"], &(&1["in"] == "path"))
        assert Enum.find(put["parameters"], &(&1["in"] == "body"))
      end
    end

    test "generates consumes and produces headers", %{config: config} do
      Dbb.Swagger.generate_swagger(config)
      file_path = Path.join(:code.priv_dir(:dbb), "static/swagger.json")
      generated_json = File.read!(file_path) |> Jason.decode!()

      for schema <- config["schemas"] do
        name = schema["name"]

        # POST and PUT should have consumes
        assert generated_json["paths"]["/api/v1/#{name}"]["post"]["consumes"] == [
                 "application/json"
               ]

        assert generated_json["paths"]["/api/v1/#{name}/{id}"]["put"]["consumes"] == [
                 "application/json"
               ]

        # All operations should have produces
        for {_, operation} <- generated_json["paths"]["/api/v1/#{name}"] do
          assert operation["produces"] == ["application/json"]
        end

        for {_, operation} <- generated_json["paths"]["/api/v1/#{name}/{id}"] do
          assert operation["produces"] == ["application/json"]
        end
      end
    end
  end
end
