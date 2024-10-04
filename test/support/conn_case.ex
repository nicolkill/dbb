defmodule DbbWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DbbWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Dbb.Accounts.Guardian

  using do
    quote do
      # The default endpoint for testing
      @endpoint DbbWeb.Endpoint

      use DbbWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import DbbWeb.ConnCase
    end
  end

  setup tags do
    Dbb.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def password, do: "some_password"

  def create_user_to_login(_) do
    user = Dbb.AccountsFixtures.user_fixture(password: password(), roles: ["all"])
    %{user: user}
  end

  def login(%{conn: conn, user: resource}) do
    {:ok, guardian_default_token, claims} = Guardian.encode_and_sign(resource)

    conn =
      conn
      |> Guardian.Plug.sign_in(resource, claims)
      |> Plug.Test.init_test_session(guardian_default_token: guardian_default_token)

    %{conn: conn}
  end
end
