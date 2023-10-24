defmodule DbbWeb.Admin.AdminLive do
  use DbbWeb, :live_view

  def mount(_params, _session, socket) do
    schemas =
      Dbb.Schema.get_config()
      |> Map.get("schemas")
      |> Enum.map(&Map.get(&1, "name"))

    {:ok, assign(socket, :schemas, schemas)}
  end
  
end