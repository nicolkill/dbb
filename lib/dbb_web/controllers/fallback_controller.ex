defmodule DbbWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use DbbWeb, :controller

  def call(conn, {nil, nil, nil}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{message: "not found body"})
  end

  def call(conn, {schema, _, {:error, nil}}) when is_bitstring(schema) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{message: "not valid body"})
  end

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: DbbWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: DbbWeb.ErrorHTML, json: DbbWeb.ErrorJSON)
    |> render(:"404")
  end
end
