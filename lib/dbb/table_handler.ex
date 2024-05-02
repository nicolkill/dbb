defmodule Dbb.TableHandler do
  @moduledoc """
  This module handles all internal operations and verifications of every table record
  """

  alias Dbb.Content
  alias Dbb.Content.Table
  alias Dbb.Schema

  defp get_config_schema(schema_name),
    do:
      Schema.get_config()
      |> Map.get("schemas")
      |> Enum.find(&(Map.get(&1, "name") == schema_name))

  defp param_to_length(param_str) do
    param_str
    |> String.replace("(", "")
    |> String.replace(")", "")
    |> String.to_integer()
  end

  defp token_process("str" <> params), do: token_to_value(params, :gen_str)
  defp token_process("num" <> params), do: token_to_value(params, :gen_num)
  defp token_process("sym" <> params), do: token_to_value(params, :gen_sym)
  defp token_process("str_num" <> params), do: token_to_value(params, :gen_str_num)
  defp token_process("any" <> params), do: token_to_value(params, :gen_any)
  defp token_process(token), do: token

  defp token_to_value(params, func) do
    length = param_to_length(params)
    apply(Dbb.Utils, func, [length])
  end

  defp generate(value) do
    value
    |> String.split("$")
    |> Enum.map(&token_process/1)
    |> Enum.join("")
  end

  defp generate_fields(nil, _), do: nil
  defp generate_fields(data, []), do: data

  defp generate_fields(data, [{key, value} | rest]) do
    value = generate(value)

    data
    |> Map.put_new(key, value)
    |> generate_fields(rest)
  end

  def type_transform(types) when is_list(types), do: Enum.map(types, &type_transform/1)
  def type_transform(type), do: String.to_atom(type)

  defp validates_data_with_schema(data, schema_fields) when is_map(data) do
    schema_fields =
      Enum.reduce(
        schema_fields,
        %{},
        fn {key, type}, acc ->
          type = type_transform(type)
          key = String.to_atom("#{key}?")
          Map.put(acc, key, type)
        end
      )

    {:ok, nil} == MapSchemaValidator.validate(schema_fields, data)
  end

  defp validates_data_with_schema(_, _), do: false

  defp validates_relations(_, nil, _), do: false

  defp validates_relations(true, data, [{key, schema} | rest]) do
    is_valid_value? = fn
      nil ->
        # todo: here check if the key it's marked as mandatory
        true

      id ->
        try do
          Content.get_table_record!(schema, id)
        rescue
          _ ->
            nil
        end
        |> is_nil()
        |> Kernel.!()
    end

    data
    |> Map.get(key)
    |> is_valid_value?.()
    |> validates_relations(data, rest)
  end

  defp validates_relations(valid?, _, _), do: valid?

  defp extract_data(schema_config, params) do
    schema_fields = Map.get(schema_config, "fields")

    relations_fields =
      schema_config
      |> Map.get("relations", %{})
      |> Map.to_list()

    generate_fields =
      schema_config
      |> Map.get("generate", %{})
      |> Map.to_list()

    general_data =
      params
      |> Map.get("data", nil)
      |> generate_fields(generate_fields)

    is_valid? =
      general_data
      |> validates_data_with_schema(schema_fields)
      |> validates_relations(general_data, relations_fields)

    if is_valid? do
      schema_fields_keys = Map.keys(schema_fields)
      {:ok, Map.take(general_data, schema_fields_keys)}
    else
      {:error, nil}
    end
  end

  def validate_schema(%{"schema" => schema} = params) do
    case get_config_schema(schema) do
      %{"name" => schema_name} = schema ->
        id = Map.get(params, "id")
        data = extract_data(schema, params)

        {schema_name, id, data}

      _ ->
        {nil, nil, nil}
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
      |> Enum.map(&{elem(&1, 0), elem(&1, 1)})

    response =
      value
      |> Map.from_struct()
      |> Map.delete(:__meta__)

    client = tesla_client()

    opts =
      [
        method: method,
        url: url,
        headers: headers
      ]
      |> Keyword.put(body_key, %{params: params, responses: response})

    Tesla.request(client, opts)

    call_hooks(rest, params, value)
  end

  def hooks(event, schema_name, params, value \\ %{}),
    do:
      get_config_schema(schema_name)
      |> Map.get("hooks", [])
      |> Enum.filter(&Enum.member?(Map.get(&1, "events"), to_string(event)))
      |> call_hooks(params, value)
end
