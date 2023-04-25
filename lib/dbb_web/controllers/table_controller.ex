defmodule DbbWeb.TableController do
  use DbbWeb, :controller

  alias Dbb.Schema
  alias Dbb.Content
  alias Dbb.Content.Table

  action_fallback DbbWeb.FallbackController

  defp module_name_simple(type) do
    case type do
      "Float" -> "number"
      "Atom" -> "boolean"
      "Integer" -> "number"
      "BitString" -> "string"
      "NaiveDateTime" -> "datetime"
      _ -> "string"
    end
  end

  defp get_data_type(nil), do: nil
  defp get_data_type(value) do
    value
    |> IEx.Info.info()
    |> Enum.find(&(elem(&1, 0) == "Data type"))
    |> elem(1)
    |> module_name_simple()
  end

  defp extract_data(schema_config, params, name) do
    schema_fields = Map.get(schema_config, "fields")
    general_data = Map.get(params, name, nil)
    is_valid? = case general_data do
      %{"data" => data} when is_map(data) ->
        Enum.reduce(schema_fields, true, fn {key, real_type}, acc ->
          value_type =
            data
            |> Map.get(key)
            |> get_data_type()

          acc and real_type == value_type
        end)

        true
      _ -> false
    end
    if is_valid?, do: {:ok, general_data}, else: {:error, nil}
  end

  defp validate_schema(%{"schema" => schema} = params) do
    result =
      Schema.get_config()
      |> Map.get("schemas")
      |> Enum.find(&(Map.get(&1, "name") == schema))

    case result do
      %{"name" => schema_name} ->
        id = Map.get(params, "id")
        data = extract_data(result, params, schema_name)

        {schema_name, id, data}
      _ -> {nil, nil, nil}
    end
  end

  def index(conn, params) do
    {schema, _, _} = validate_schema(params)

    table = Content.list_table(schema)
    render(conn, :index, table: table)
  end

  def show(conn, params) do
    {schema, id, _} = validate_schema(params)

    table = Content.get_table!(schema, id)
    render(conn, :show, table: table)
  end

  def create(conn, params) do
    with {schema, _, {:ok, data}} <- validate_schema(params),
         {:ok, %Table{} = table} <- Content.create_table(schema, data) do
      conn
      |> put_status(201)
      |> render(:show, table: table)
    end
  end

  def update(conn, params) do
    with {schema, id, {:ok, data}} <- validate_schema(params),
         table <- Content.get_table!(schema, id),
         {:ok, %Table{} = table} <- Content.update_table(table, data) do
      render(conn, :show, table: table)
    end
  end

  def delete(conn, params) do
    {schema, id, _} = validate_schema(params)
    table = Content.get_table!(schema, id)

    with {:ok, %Table{}} <- Content.delete_table(table) do
      send_resp(conn, :no_content, "")
    end
  end
end
