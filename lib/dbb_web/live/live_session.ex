defmodule DbbWeb.LiveSession do

  import Phoenix.Component

  alias Dbb.Accounts.Guardian

  def on_mount(_, _params, %{"guardian_default_token" => guardian_default_token}, socket) do
    {:ok, current_user, _} = Guardian.resource_from_token(guardian_default_token)

    socket =
      assign(socket, :current_user, current_user)

    {:cont, socket}
  end
end