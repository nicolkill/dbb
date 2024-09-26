defmodule DbbWeb.Admin.AdminLive do
  use DbbWeb, :live_view

  alias Dbb.Schema

  def mount(_params, _session, %{assigns: %{structured_permissions: roles}} = socket) do
    schemas =
      Schema.get_config()
      |> Map.get("schemas")
      |> Enum.map(&Map.get(&1, "name"))
      |> Enum.filter(
        &(TrollBridge.allowed?(roles, "admin", "all") or TrollBridge.allowed?(roles, &1, "all") or
            TrollBridge.allowed?(roles, &1, "index"))
      )

    {:ok, assign(socket, :schemas, schemas)}
  end

  def link(:root),
    do: "/admin"

  def link(:index, schema_name),
    do: "/admin/#{schema_name}"

  def link(:create, schema_name),
    do: "/admin/#{schema_name}/create"

  def link(:update, schema_name, id),
    do: "/admin/#{schema_name}/update/#{id}"
end
