defmodule DbbWeb.UserLive.Login do
  use DbbWeb, :live_view

  alias Dbb.Accounts
  alias Dbb.Accounts.Guardian

  @impl true
  def mount(_params, _session, socket) do
    initial_data = %{
      "email" => "",
      "password" => ""
    }

    socket =
      socket
      |> assign(:form, to_form(initial_data))

    {:ok, socket, layout: {DbbWeb.Layouts, :login}}
  end

  @impl true
  def handle_event("save", params, socket) do
    %{"email" => email, "password" => password} = params

    socket =
      case Accounts.login_email(email, password) do
        nil ->
          socket

        user ->
          {:ok, token, _} = Guardian.encode_and_sign(user)

          query_params = URI.encode_query(%{"token" => token})

          redirect(socket, to: "/login_save?#{query_params}")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", params, socket) do
    params = Map.take(params, ["email", "password"])
    errors = params_errors(params)

    {:noreply,
     socket
     |> assign(:form, to_form(params, errors: errors))}
  end

  defp params_errors(params) do
    params
    |> Map.to_list()
    |> Enum.flat_map(fn
      {"email", email} ->
        if Dbb.Utils.validate_email(email) do
          []
        else
          [{:email, {"invalid email", []}}]
        end

      _ ->
        []
    end)
  end
end
