defmodule Dbb.Plugs.BasicApiAuth do
  import Plug.Conn

  defp api_key, do: Application.get_env(:dbb, :general_config)[:api_key]

  def init(opts), do: opts

  def call(conn, _) do
    key = api_key()

    case {key, get_req_header(conn, "authorization")} do
      {key, ["Bearer " <> token]} when not is_nil(key) ->
        process_token(conn, key == token)

      {key, _} when not is_nil(key) ->
        unauthorized(conn)

      {nil, _} ->
        conn
    end
  end

  defp process_token(conn, true), do: conn
  defp process_token(conn, _), do: unauthorized(conn)

  defp unauthorized(conn) do
    resp = Jason.encode!(%{error: %{detail: "Unauthorized"}})

    conn
    |> send_resp(401, resp)
    |> halt()
  end
end
