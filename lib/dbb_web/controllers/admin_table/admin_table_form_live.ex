defmodule DbbWeb.AdminTable.AdminTableFormLive do
  use DbbWeb, :live_view

  alias Dbb.TableApi

  alias Dbb.Schema
  alias Dbb.Content.Table
  alias Dbb.TableHandler
  alias DbbWeb.Admin.AdminLive

  @action_create "create"
  @action_update "update"
  @saved_message "Record saved!"
  @field_error_message "Is invalid value"

  def mount(%{"id" => _} = params, _session, socket) do
    {:ok, %Table{data: record} = db_record} = TableApi.show(params)
    schema = TableHandler.get_config_schema(db_record.schema)

    socket =
      socket
      |> assign(:action, @action_update)
      |> configure_socket(schema, record, db_record)

    {:ok, socket}
  rescue
    _ ->
      {:ok, assign(socket, :not_found, true)}
  end

  def mount(params, _session, socket) do
    schema_name = Map.get(params, "schema")
    schema = TableHandler.get_config_schema(schema_name)

    default_record = Schema.schema_default_record(schema)

    socket =
      socket
      |> assign(:action, @action_create)
      |> configure_socket(schema, default_record)

    {:ok, socket}
  end

  def handle_event("save", _, socket) do
    action = get_assign(socket, :action)
    schema_name = get_assign(socket, :schema_name)
    schema_fields = get_assign(socket, :schema_fields)

    record =
      socket
      |> get_assign(:record)
      |> transform_record_values(schema_fields)
      |> Map.to_list()
      |> Enum.reduce(%{}, fn
        {_, ""}, acc ->
          acc

        {k, v}, acc ->
          Map.put(acc, k, v)
      end)

    params = %{"schema" => schema_name, "data" => record}

    {func, args} =
      case action do
        @action_create ->
          {:create, [params]}

        @action_update ->
          db_record = get_assign(socket, :db_record)
          {:update, [Map.put(params, "id", db_record.id)]}
      end

    {:ok, %Table{id: id}} = apply(TableApi, func, args)

    socket =
      socket
      |> put_flash(:info, @saved_message)
      |> redirect(to: AdminLive.link(:update, schema_name, id))

    {:noreply, socket}
  end

  def handle_event("validate", %{"_target" => [field]} = params, socket) do
    schema_fields = get_assign(socket, :schema_fields)

    value =
      params
      |> Map.get(field)
      |> Schema.value_to_type(Map.get(schema_fields, field))

    record =
      socket
      |> get_assign(:record)
      |> Map.put(field, value)

    errors =
      record
      |> get_invalid_fields(schema_fields)
      |> Enum.map(&{String.to_atom(&1), {@field_error_message, []}})

    socket =
      socket
      |> assign(:record, record)
      |> assign(:form, to_form(record, errors: errors))

    {:noreply, socket}
  end

  defp get_assign(socket, key),
    do:
      socket
      |> Map.get(:assigns)
      |> Map.get(key)

  defp get_invalid_fields(record, schema_fields) do
    record = transform_record_values(record, schema_fields)

    result =
      schema_fields
      |> transform_schema_fields_to_optional()
      |> MapSchemaValidator.validate(record)

    case result do
      {:error, %MapSchemaValidator.InvalidMapError{message: message}} ->
        message
        |> String.replace("error at: ", "")
        |> String.replace(" -> ", ",")
        |> String.split(",")

      _ ->
        []
    end
  end

  defp configure_socket(socket, schema, record, db_record \\ nil) do
    schema_fields = Map.get(schema, "fields")
    record = transform_record_values(record, schema_fields)

    socket
    |> assign(:schema_name, Map.get(schema, "name"))
    |> assign(:schema_fields, schema_fields)
    |> assign(:schema_hooks, Map.get(schema, "hooks"))
    |> assign(:record, record)
    |> assign(:db_record, db_record)
    |> assign(:form, to_form(record))
  end

  defp transform_schema_fields_to_optional(schema_fields) do
    Enum.reduce(schema_fields, %{}, fn {key, type}, acc ->
      key = String.to_atom("#{key}?")
      type = TableHandler.type_transform(type)
      Map.put(acc, key, type)
    end)
  end

  defp tuple_list_to_map(list) do
    Enum.reduce(list, %{}, &Map.put(&2, elem(&1, 0), elem(&1, 1)))
  end

  defp transform_record_values(record, schema_fields) do
    list_fields = get_list_fields(schema_fields)

    list_records =
      record
      |> Map.take(Map.keys(list_fields))
      |> Enum.map(fn
        {k, v} when is_list(v) ->
          {k, Enum.join(v, ", ")}

        {k, v} ->
          {k, v |> String.split(",") |> Enum.map(&String.trim/1)}
      end)
      |> tuple_list_to_map()

    Map.merge(record, list_records)
  end

  defp get_list_fields(schema_fields) do
    schema_fields
    |> Enum.filter(&is_list(elem(&1, 1)))
    |> tuple_list_to_map()
  end
end
