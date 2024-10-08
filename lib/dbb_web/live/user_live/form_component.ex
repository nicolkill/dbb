defmodule DbbWeb.UserLive.FormComponent do
  use DbbWeb, :live_component

  alias Dbb.Accounts
  alias Dbb.Schema
  alias Dbb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage user records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:username]} type="text" label="Username" />
        <.input field={@form[:email]} type="text" label="Email" />
        <.input field={@form[:first_name]} type="text" label="First name" />
        <.input field={@form[:last_name]} type="text" label="Last name" />
        <.input field={@form[:password]} type="password" label="Password" />
        <span class="!mt-8 block font-bold text-sm">
          Permissions
        </span>
        <.input
          value={has_permission?(@roles, "all")}
          name="permissions[all]"
          type="checkbox"
          label="All"
        />
        <div :for={{role, permissions} <- Map.to_list(@schema_roles)} class="flex flex-wrap gap-4">
          <span class="basis-1/4 font-bold">
            <%= Utils.capitalize_snake_case(role) %>
          </span>
          <.input
            :for={permission <- permissions}
            class="basis-1/4"
            value={has_permission?(@roles, "#{role}.#{permission}")}
            name={"permissions[#{role}.#{permission}]"}
            type="checkbox"
            label={Utils.capitalize_snake_case(permission)}
          />
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save User</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Accounts.change_user(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:schema_roles, Schema.schema_roles())
     |> assign(:roles, user.roles)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params, "permissions" => permissions}, socket) do
    roles = roles_format(permissions)
    user_params = Map.put(user_params, "roles", roles)

    changeset =
      socket.assigns.user
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:roles, roles)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("save", %{"user" => user_params}, %{assigns: %{roles: roles}} = socket) do
    user_params
    |> Map.put("roles", roles)
    |> then(&save_user(socket, socket.assigns.action, &1))
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp roles_format(permissions_params) do
    permissions_params
    |> Map.to_list()
    |> Enum.flat_map(&if elem(&1, 1) == "true", do: [elem(&1, 0)], else: [])
  end

  defp has_permission?(roles, permission) do
    roles
    |> Enum.find(&(&1 == permission))
    |> is_nil()
    |> Kernel.!()
  end
end
