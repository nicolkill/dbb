defmodule DbbWeb.SetupLive.Index do
  use DbbWeb, :live_view

  alias Dbb.Accounts

  @default_admin_email "admin2@admin.com"

  @impl true
  def mount(_params, _session, socket) do
    case Accounts.get_user_by_email(@default_admin_email) do
      nil ->
        {:ok, socket, layout: {DbbWeb.Layouts, :login}}

      _ ->
        {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  @impl true
  def handle_event("delete", _, socket) do
    {:ok, _} =
      Accounts.create_user(%{
        "username" => "admin",
        "email" => @default_admin_email,
        "password" => "pass",
        "roles" => ["all"]
      })

    {:noreply, socket}
  end
  
end