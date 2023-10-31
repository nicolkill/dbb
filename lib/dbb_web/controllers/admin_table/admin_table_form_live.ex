defmodule DbbWeb.AdminTable.AdminTableFormLive do
  use DbbWeb, :live_view

  alias Dbb.Schema
  alias Dbb.Content
  alias Dbb.Content.Table
  alias Dbb.TableHandler
  alias DbbWeb.Admin.AdminLive

  @action_create "create"
  @action_update "update"
  @saved_message "Record saved!"
  @field_error_message "Is invalid value"

  def mount(%{"id" => _} = params, _session, socket) do
    {schema_name, id, _} = TableHandler.validate_schema(params)
    %Table{data: record} = db_record = Content.get_table_record!(schema_name, id)

    schema =
      Schema.get_config()
      |> Map.get("schemas")
      |> Enum.find(&(Map.get(&1, "name") == schema_name))

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
    {schema_name, _, _} = TableHandler.validate_schema(params)

    schema =
      Schema.get_config()
      |> Map.get("schemas")
      |> Enum.find(&(Map.get(&1, "name") == schema_name))

    default_record = Schema.schema_default_record(schema)

    socket =
      socket
      |> assign(:action, @action_create)
      |> configure_socket(schema, default_record)

    {:ok, socket}
  end

  def handle_event("save", _, socket) do
    record = get_assign(socket, :record)
    action = get_assign(socket, :action)
    schema_name = get_assign(socket, :schema_name)

    {func, args} =
      case action do
        @action_create ->
          {:create_table_record, [schema_name, record]}

        @action_update ->
          db_record = get_assign(socket, :db_record)
          {:update_table_record, [db_record, record]}
      end

    {:ok, %Table{id: id}} = apply(Content, func, args)

    #    action
    #    |> String.to_atom()
    #    |> TableHandler.hooks(schema_name, %{}, record)

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
    result =
      schema_fields
      |> Enum.reduce(%{}, &Map.put(&2, String.to_atom(elem(&1, 0)), String.to_atom(elem(&1, 1))))
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
    socket
    |> assign(:schema_name, Map.get(schema, "name"))
    |> assign(:schema_fields, Map.get(schema, "fields"))
    |> assign(:schema_hooks, Map.get(schema, "hooks"))
    |> assign(:record, record)
    |> assign(:db_record, db_record)
    |> assign(:form, to_form(record))
  end
end
