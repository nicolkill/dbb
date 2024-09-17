defmodule DbbWeb.AdminTable.AdminTableLive do
  use DbbWeb, :live_view

  alias Dbb.TableApi
  alias Dbb.TableHandler
  alias Dbb.Content.Table

  @page_records_count 10

  @impl true
  def mount(params, _session, socket) do
    schema_name = Map.get(params, "schema")

    schema = TableHandler.get_config_schema(schema_name)

    socket =
      socket
      |> assign(:schema_name, schema_name)
      |> assign(:schema_fields, Map.get(schema, "fields"))
      |> assign(:schema_hooks, Map.get(schema, "hooks"))
      |> load_data(0)
      |> assign(:to_delete, nil)
      |> assign(:page_records_count, @page_records_count)

    {:ok, socket}
  end

  @impl true
  def handle_event("first_page", _, %{assigns: %{page: page}} = socket) do
    {:noreply, load_data(socket, 0)}
  end

  @impl true
  def handle_event("previous_page", _, %{assigns: %{page: page}} = socket) do
    {:noreply, load_data(socket, page - 1)}
  end

  @impl true
  def handle_event("next_page", _, %{assigns: %{page: page}} = socket) do
    {:noreply, load_data(socket, page + 1)}
  end

  @impl true
  def handle_event("delete", %{"row-id" => id}, socket) do
    {:noreply, assign(socket, :to_delete, id)}
  end

  @impl true
  def handle_event("delete-record", _, socket) do
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

    true =
      TableApi.delete(%{
        id: table_record.id,
        schema: table_record.schema
      })

    socket =
      socket
      |> assign(:table_data, table_data)
      |> assign(:to_delete, nil)

    {:noreply, socket}
  end

  defp load_data(%{assigns: %{schema_name: schema_name}} = socket, page) do
    # todo: add filters here
    %{
      table: table_data,
      count: count
    } =
      TableApi.index(%{
        schema: schema_name,
        page: page,
        count: @page_records_count
      })

    socket
    |> assign(:table_data, table_data)
    |> assign(:page, page)
    |> assign(:count, count)
  end

  defp get_assign(socket, key),
    do:
      socket
      |> Map.get(:assigns)
      |> Map.get(key)

  defp render_field(row, type, field) do
    value =
      row
      |> Map.get(:data)
      |> Map.get(field)

    case {type, value} do
      {"boolean", _} ->
        checkbox(%{checked: value})

      {_, value} when is_list(value) ->
        Enum.join(value, ", ")

      _ ->
        value
    end
  end
end
