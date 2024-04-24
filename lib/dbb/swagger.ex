defmodule Dbb.Swagger do
  defp schema_request_title(cap_name), do: "#{cap_name}Request"
  defp schema_response_title(cap_name), do: "#{cap_name}Response"
  defp schemas_response_title(cap_name), do: "#{cap_name}ResponseMulti"

  defp value_example("number"), do: 10
  defp value_example("float"), do: 10.0
  defp value_example("integer"), do: 10
  defp value_example("boolean"), do: true
  defp value_example("time"), do: "00:00:00"
  defp value_example("date"), do: "2023-09-05"
  defp value_example("datetime"), do: "2023-09-05 00:00:00"
  defp value_example("string"), do: "some string value"
  defp value_example("uuid"), do: "3f0a4ef1-45e1-4cf3-8187-f7c7ec000fa0"

  defp swg_properties(value) when value in ["number", "float"], do: %{"type" => "number"}
  defp swg_properties("string"), do: %{"type" => "string"}

  defp swg_properties("time"),
    do: %{"type" => "string", "pattern" => "/^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/"}

  defp swg_properties("date"), do: %{"type" => "string", "format" => "date"}
  defp swg_properties("datetime"), do: %{"type" => "string", "format" => "date-time"}
  defp swg_properties("integer"), do: %{"type" => "integer"}
  defp swg_properties("boolean"), do: %{"type" => "boolean"}

  defp cap_name(schema), do: Utils.modularize_snake_case(schema["name"])

  defp swg_parameter_path_id(schema) do
    %{
      "description" => "#{schema["name"]} ID",
      "in" => "path",
      "name" => "id",
      "required" => true,
      "type" => "string",
      "x-example" => value_example("uuid")
    }
  end

  defp swg_parameter_body_schema(schema) do
    cap_name = cap_name(schema)

    %{
      "description" => "The #{schema["name"]} details",
      "in" => "body",
      "name" => schema["name"],
      "required" => false,
      "schema" => %{
        "$ref" => "#/definitions/#{schema_request_title(cap_name)}"
      },
      "x-schema" => %{
        "data" => %{
          "data" => swg_schema_example(schema)
        }
      }
    }
  end

  defp swg_schema_example(schema),
    do:
      Enum.reduce(schema["fields"], %{}, fn {f, t}, acc ->
        Map.put(acc, f, value_example(t))
      end)

  defp swg_schema(schema) do
    cap_name = cap_name(schema)

    %{
      "title" => cap_name,
      "type" => "object",
      "description" => Map.get(schema, "description", ""),
      "example" => swg_schema_example(schema),
      "properties" =>
        Enum.reduce(schema["fields"], %{}, fn {f, t}, acc ->
          Map.put(acc, f, swg_properties(t))
        end)
    }
  end

  defp swg_schema_request(schema) do
    cap_name = cap_name(schema)

    %{
      "title" => schema_request_title(cap_name),
      "type" => "object",
      "description" => "POST body for creating a #{cap_name}",
      "properties" => %{
        "data" => %{
          "$ref" => "#/definitions/#{cap_name}",
          "description" => "The #{schema["name"]} details"
        }
      }
    }
  end

  defp swg_schema_response(schema) do
    cap_name = cap_name(schema)

    %{
      "title" => schema_response_title(cap_name),
      "type" => "object",
      "description" => "POST body for creating a #{cap_name}",
      "properties" => %{
        "data" => %{
          "type" => "object",
          "properties" => %{
            "schema" => swg_properties("string"),
            "id" => swg_properties("string"),
            "reference" => swg_properties("string"),
            "inserted_at" => swg_properties("datetime"),
            "updated_at" => swg_properties("datetime"),
            "data" => %{
              "$ref" => "#/definitions/#{cap_name}",
              "description" => "The #{schema["name"]} details"
            }
          }
        }
      }
    }
  end

  defp swg_schemas_response(schema) do
    cap_name = cap_name(schema)

    %{
      "title" => schemas_response_title(cap_name),
      "type" => "object",
      "description" => "POST body for creating a #{cap_name}",
      "properties" => %{
        "page" => %{
          "type" => "integer"
        },
        "count" => %{
          "type" => "integer"
        },
        "data" => %{
          "description" => "Response schema for multiple #{schema["name"]}s",
          "type" => "array",
          "items" => %{
            "$ref" => "#/definitions/#{schema_response_title(cap_name)}"
          }
        }
      }
    }
  end

  defp swg_call_get_all(schema) do
    cap_name = cap_name(schema)

    %{
      "description" => "List all #{schema["name"]} in the database",
      "parameters" => [],
      "produces" => ["application/json"],
      "summary" => "List #{cap_name}s",
      "tags" => [cap_name],
      "responses" => %{
        "200" => %{
          "description" => "OK",
          "schema" => %{
            "$ref" => "#/definitions/#{schemas_response_title(cap_name)}"
          },
          "examples" => %{
            "application/json" => %{
              "page" => 1,
              "count" => 20,
              "data" => [
                %{
                  "schema" => schema["name"],
                  "id" => value_example("uuid"),
                  "reference" => value_example("uuid"),
                  "inserted_at" => value_example("datetime"),
                  "updated_at" => value_example("datetime"),
                  "data" => swg_schema_example(schema)
                }
              ]
            }
          }
        }
      }
    }
  end

  defp swg_call_get_one(schema) do
    cap_name = cap_name(schema)

    %{
      "description" => "Show a #{schema["name"]} by ID",
      "parameters" => [
        swg_parameter_path_id(schema)
      ],
      "produces" => ["application/json"],
      "summary" => "Show #{cap_name}",
      "tags" => [cap_name],
      "responses" => %{
        "200" => %{
          "description" => "OK",
          "schema" => %{
            "$ref" => "#/definitions/#{schema_response_title(cap_name)}"
          },
          "examples" => %{
            "application/json" => %{
              "data" => [
                %{
                  "schema" => schema["name"],
                  "id" => value_example("uuid"),
                  "reference" => value_example("uuid"),
                  "inserted_at" => value_example("datetime"),
                  "updated_at" => value_example("datetime"),
                  "data" => swg_schema_example(schema)
                }
              ]
            }
          }
        }
      }
    }
  end

  defp swg_call_post(schema) do
    cap_name = cap_name(schema)

    %{
      "consumes" => ["application/json"],
      "description" => "Create a new #{schema["name"]}",
      "parameters" => [
        swg_parameter_body_schema(schema)
      ],
      "produces" => ["application/json"],
      "summary" => "Create #{cap_name}",
      "tags" => [cap_name],
      "responses" => %{
        "201" => %{
          "description" => "#{cap_name} created OK",
          "schema" => %{
            "$ref" => "#/definitions/#{schema_response_title(cap_name)}"
          },
          "examples" => %{
            "application/json" => %{
              "data" => [
                %{
                  "schema" => schema["name"],
                  "id" => value_example("uuid"),
                  "reference" => value_example("uuid"),
                  "inserted_at" => value_example("datetime"),
                  "updated_at" => value_example("datetime"),
                  "data" => swg_schema_example(schema)
                }
              ]
            }
          }
        }
      }
    }
  end

  defp swg_call_put(schema) do
    cap_name = cap_name(schema)

    %{
      "consumes" => ["application/json"],
      "description" => "Update all attributes of a #{schema["name"]}",
      "parameters" => [
        swg_parameter_path_id(schema),
        swg_parameter_body_schema(schema)
      ],
      "produces" => ["application/json"],
      "summary" => "Update #{cap_name}",
      "tags" => [cap_name],
      "responses" => %{
        "200" => %{
          "description" => "Updated Successfully",
          "schema" => %{
            "$ref" => "#/definitions/#{schema_response_title(cap_name)}"
          },
          "examples" => %{
            "application/json" => %{
              "data" => [
                %{
                  "schema" => schema["name"],
                  "id" => value_example("uuid"),
                  "reference" => value_example("uuid"),
                  "inserted_at" => value_example("datetime"),
                  "updated_at" => value_example("datetime"),
                  "data" => swg_schema_example(schema)
                }
              ]
            }
          }
        }
      }
    }
  end

  defp swg_call_delete(schema) do
    cap_name = cap_name(schema)

    %{
      "description" => "Delete a #{schema["name"]} by ID",
      "parameters" => [
        swg_parameter_path_id(schema)
      ],
      "produces" => ["application/json"],
      "summary" => "Delete #{cap_name}",
      "tags" => [cap_name],
      "responses" => %{
        "203" => %{
          "description" => "No Content - Deleted Successfully"
        }
      }
    }
  end

  defp swg_schema_crud_no_id(schema) do
    %{
      "get" => swg_call_get_all(schema),
      "post" => swg_call_post(schema)
    }
  end

  defp swg_schema_crud_with_id(schema) do
    %{
      "get" => swg_call_get_one(schema),
      "put" => swg_call_put(schema),
      "delete" => swg_call_delete(schema)
    }
  end

  def generate_swagger(config) do
    schemas = Map.get(config, "schemas")

    definitions =
      Enum.reduce(schemas, %{}, fn schema, acc ->
        cap_name = cap_name(schema)

        acc
        |> Map.put(cap_name, swg_schema(schema))
        |> Map.put(schema_request_title(cap_name), swg_schema_request(schema))
        |> Map.put(schema_response_title(cap_name), swg_schema_response(schema))
        |> Map.put(schemas_response_title(cap_name), swg_schemas_response(schema))
      end)

    paths =
      Enum.reduce(schemas, %{}, fn schema, acc ->
        acc
        |> Map.put("/api/v1/#{schema["name"]}", swg_schema_crud_no_id(schema))
        |> Map.put("/api/v1/#{schema["name"]}/{id}", swg_schema_crud_with_id(schema))
      end)

    content = %{
      "swagger" => "2.0",
      "info" => %{
        "version" => "1.0",
        "title" => "dbb"
      },
      "paths" => paths,
      "definitions" => definitions
    }

    file_path =
      :dbb
      |> :code.priv_dir()
      |> (&"#{&1}/static/swagger.json").()

    :ok = File.write(file_path, Jason.encode!(content))
  end
end
