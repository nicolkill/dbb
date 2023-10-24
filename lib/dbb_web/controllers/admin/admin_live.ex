defmodule DbbWeb.Admin.AdminLive do
  use DbbWeb, :live_view

#  def mount(%{"house" => _house}, %{"current_user_id" => user_id} = _session, socket) do
#    {:ok, assign(socket, :temperature, temperature)}
#  end

  def mount(_params, _session, socket) do
    temperature = 70
    {:ok, assign(socket, :temperature, temperature)}
  end
  
end