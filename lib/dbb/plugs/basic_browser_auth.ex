defmodule Dbb.Plugs.BasicBrowserAuth do
  defp basic_auth, do: Application.get_env(:dbb, :basic_auth)

  def init(opts), do: opts

  def call(conn, _) do
    basic_auth_config = basic_auth()

    case Keyword.get(basic_auth_config, :enabled?, false) and Mix.env() != :test do
      true ->
        Plug.BasicAuth.basic_auth(conn, basic_auth_config)

      _ ->
        conn
    end
  end
end
