defmodule Dbb.TableHandler do

  alias Dbb.Schema
  alias Dbb.Content.Table

  defp get_config_schema(schema_name),
       do: Schema.get_config()
           |> Map.get("schemas")
           |> Enum.find(&(Map.get(&1, "name") == schema_name))

  defp module_name_simple(type) do
    case type do
      "Float" -> "number"
      "Atom" -> "boolean"
      "Integer" -> "number"
      "BitString" -> "string"
      "NaiveDateTime" -> "string"
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

  defp extract_data(schema_config, params) do
    schema_fields = Map.get(schema_config, "fields")
    general_data = Map.get(params, "data", nil)
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

  def validate_schema(%{"schema" => schema} = params) do
    schema = get_config_schema(schema)

    case schema do
      %{"name" => schema_name} ->
        id = Map.get(params, "id")
        data = extract_data(schema, params)

        {schema_name, id, data}
      _ -> {nil, nil, nil}
    end
  end

  def pagination(params) do
    page =
      params
      |> Map.get("page", "0")
      |> String.to_integer()
    count =
      params
      |> Map.get("count", "10")
      |> String.to_integer()

    {page, count}
  end

  def search(params) do
    query =
      params
      |> Map.get("q", "")
      |> String.split(";")
      |> Enum.map(fn raw_tuple ->
        case String.split(raw_tuple, ":") do
          [key, value] -> {key, value}
          _ -> {}
        end
      end)

    query
  end

  defp tesla_client() do
    middleware = [
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware)
  end

  defp call_hooks([], _params, _value), do: :pass
  defp call_hooks([hook | rest], params, %Table{} = value) do
    method =
      hook
      |> Map.get("method", "get")
      |> String.to_atom()
    body_key = if method == :get, do: :query, else: :body
    url = Map.get(hook, "url")
    headers =
      hook
      |> Map.get("headers")
      |> Enum.map(&({elem(&1, 0), elem(&1, 1)}))
    response =
      value
      |> Map.from_struct()
      |> Map.delete(:__meta__)
    client = tesla_client()

    opts = [
      method: method,
      url: url,
      headers: headers
    ]
    |> Keyword.put(body_key, %{params: params, responses: response})

    Tesla.request(client, opts)

    call_hooks(rest, params, value)
  end

  def hooks(event, schema_name, params, value \\ %{}),
       do: get_config_schema(schema_name)
           |> Map.get("hooks")
           |> Enum.filter(&(to_string(event) in Map.get(&1, "events")))
           |> call_hooks(params, value)
end