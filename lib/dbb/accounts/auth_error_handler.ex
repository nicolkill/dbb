defmodule Dbb.Accounts.AuthErrorHandler do

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, data, _opts) do
    path =
      case data do
        {:already_authenticated, _} ->
          "/admin"
        _ ->
          "/login"
      end

    Phoenix.Controller.redirect(conn, to: path)
  end
end