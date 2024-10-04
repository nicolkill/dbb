defmodule DbbWeb.SetupLiveTest do
  use DbbWeb.ConnCase

  import Phoenix.LiveViewTest

  @default_admin_email "admin@admin.com"

  alias Dbb.Accounts
  alias Dbb.AccountsFixtures

  describe "Login" do
    test "redirects to login", %{conn: conn} do
      AccountsFixtures.user_fixture(%{"email" => @default_admin_email})

      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/admin/setup")
    end

    test "can login", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/setup")

      view
      |> element("button[phx-click=start_setup]")
      |> render_click()

      assert %{email: email} = Accounts.get_user_by_email(@default_admin_email)
      assert email == @default_admin_email
      assert {path, _} = assert_redirect(view)
      assert path =~ "/login"
    end
  end
end
