defmodule DbbWeb.AdminTable.AdminTableLive do
  use DbbWeb, :live_view

  alias Dbb.TableHandler
  alias Dbb.Content

  def mount(params, _session, socket) do
    {schema_name, _, _} = TableHandler.validate_schema(params)
                     |> IO.inspect(label: "table_data")
    {page, count} = TableHandler.pagination(params)
    query = TableHandler.search(params)

    table_data = Content.list_table(schema_name, query, page, count)

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

    {:ok, socket}
  end

  def link(:create, schema_name),
      do: "/#{schema_name}/create"

end