defmodule DbbWeb.LiveSession do
  import Phoenix.Component

  alias Dbb.Accounts.Guardian
  alias Dbb.Accounts.TrollBridge, as: LocalTrollBridge

  def on_mount(_, _params, %{"guardian_default_token" => guardian_default_token}, socket) do
    {:ok, current_user, _} = Guardian.resource_from_token(guardian_default_token)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(
        :structured_permissions,
        LocalTrollBridge.roles_to_permissions(current_user.roles)
      )

    {:cont, socket}
  end
end
