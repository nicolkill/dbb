defmodule DbbWeb.Admin.AdminLive do
  use DbbWeb, :live_view

  def mount(_params, _session, socket) do
    schemas =
      Dbb.Schema.get_config()
      |> Map.get("schemas")
      |> Enum.map(&Map.get(&1, "name"))

    {:ok, assign(socket, :schemas, schemas)}
  end

  def link(:root),
      do: "/"
  def link(:index, schema_name),
      do: "/#{schema_name}"
  def link(:create, schema_name),
      do: "/#{schema_name}/create"
  def link(:update, schema_name, id),
      do: "/#{schema_name}/update/#{id}"
  
end