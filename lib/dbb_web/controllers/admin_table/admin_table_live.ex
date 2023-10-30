defmodule DbbWeb.AdminTable.AdminTableLive do
  use DbbWeb, :live_view

  alias Dbb.TableHandler
  alias Dbb.Content
  alias Dbb.Content.Table

  def mount(params, _session, socket) do
    {schema_name, _, _} = TableHandler.validate_schema(params)
    {page, count} = TableHandler.pagination(params)
    query = TableHandler.search(params)

    table_data = Content.list_table_records(schema_name, query, page, count)
      |> IO.inspect(label: "############ table_data")

    schema =
      Dbb.Schema.get_config()
      |> Map.get("schemas")
      |> Enum.find(&(Map.get(&1, "name") == schema_name))

    socket =
      socket
      |> assign(:schema_name, schema_name)
      |> assign(:schema_fields, Map.get(schema, "fields"))
      |> assign(:schema_hooks, Map.get(schema, "hooks"))
      |> assign(:page, page)
      |> assign(:count, count)
      |> assign(:table_data, table_data)
      |> assign(:to_delete, nil)

    {:ok, socket}
  end

  defp get_assign(socket, key),
       do: socket
           |> Map.get(:assigns)
           |> Map.get(key)

  def render_field(row, type, field) do
    value =
      row
      |> Map.get(:data)
      |> Map.get(field)

    case type do
      "boolean" ->
        checkbox(%{checked: value})
      _ ->
        value
    end
  end

  def handle_event("delete", %{"row-id" => id}, socket) do
    {:noreply, assign(socket, :to_delete, id)}
  end

  def handle_event("delete-record", _, socket) do
    schema_name = get_assign(socket, :schema_name)
    to_delete_id = get_assign(socket, :to_delete)

    {table_data, table_record} =
      socket
      |> get_assign(:table_data)
      |> Enum.reduce({[], []}, fn
        %Table{id: id} = record, {data, _} when id == to_delete_id ->
          {data, record}
        record, {data, founded} ->
          {data ++ [record], founded}
      end)

    {:ok, %Table{}} = Content.delete_table_record(table_record)

#    TableHandler.hooks(:delete, schema_name, %{}, table_record)

    socket =
      socket
      |> assign(:table_data, table_data)
      |> assign(:to_delete, nil)

    {:noreply, socket}
  end

end