defmodule DbbWeb.UserLive.Show do
  use DbbWeb, :live_view

  alias Dbb.Accounts

  @impl true
  def mount(_params, _session, %{assigns: %{structured_permissions: structured_permissions}} = socket) do
    socket =
      if TrollBridge.allowed?(structured_permissions, "admin", "all") do
        socket
      else
        socket
        |> put_flash(:error, "Access Denied")
        |> redirect(to: ~p"/admin")
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:user, Accounts.get_user!(id))}
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"
end
