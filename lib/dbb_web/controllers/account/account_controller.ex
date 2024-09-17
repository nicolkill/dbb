defmodule DbbWeb.AccountController do
  use DbbWeb, :controller

  alias Dbb.Accounts.Guardian

  action_fallback DbbWeb.FallbackController

  def login(conn, %{"token" => token}) do
    {:ok, resource, claims} = Guardian.resource_from_token(token)

    conn
    |> Guardian.Plug.sign_in(resource, claims)
    |> redirect(to: ~p"/admin")
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: ~p"/login")
  end
end