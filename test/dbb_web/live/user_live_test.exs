defmodule DbbWeb.UserLiveTest do
  use DbbWeb.ConnCase

  import Phoenix.LiveViewTest

  @create_attrs %{
    email: "email@example.com",
    first_name: "some first_name",
    last_name: "some last_name",
    password: "some password",
    username: "some username"
  }
  @update_attrs %{
    email: "email_updated@example.com",
    first_name: "some updated first_name",
    last_name: "some updated last_name",
    password: "some updated password",
    username: "some updated username"
  }
  @invalid_attrs %{email: nil, first_name: nil, last_name: nil, password: nil, username: nil}

  describe "Login" do
    setup [:create_user_to_login]

    test "redirects to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/admin/users")
    end

    test "can login", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/login")

      refute view
             |> element("form#login-form")
             |> render_change(%{
               email: user.email,
               password: password()
             }) =~
               "invalid email"

      view
      |> element("form#login-form")
      |> render_submit()

      assert {path, _} = assert_redirect(view)
      assert path =~ "/login_save?token="
    end
  end

  describe "Logout" do
    setup [:create_user_to_login, :login]

    test "performs logout", %{conn: conn, user: user} do
      conn = get(conn, ~p"/admin/logout")

      assert "/login" =~ redirected_to(conn)
    end
  end

  describe "Index" do
    setup [:create_user_to_login, :login]

    test "lists all users", %{conn: conn, user: user} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/users")

      assert html =~ "Listing Users"
      assert html =~ user.email
    end

    test "saves new user", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("a", "New User") |> render_click() =~
               "New User"

      assert_patch(index_live, ~p"/admin/users/new")

      assert index_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#user-form", user: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/users")

      html = render(index_live)
      assert html =~ "User created successfully"
      assert html =~ "email@example.com"
    end

    test "updates user in listing", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("#users-#{user.id} a", "Edit") |> render_click() =~
               "Edit User"

      assert_patch(index_live, ~p"/admin/users/#{user}/edit")

      assert index_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#user-form", user: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/users")

      html = render(index_live)
      assert html =~ "User updated successfully"
      assert html =~ "email_updated@example.com"
    end

    test "deletes user in listing", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("#users-#{user.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#users-#{user.id}")
    end
  end

  describe "Show" do
    setup [:create_user_to_login, :login]

    test "displays user", %{conn: conn, user: user} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/users/#{user}")

      assert html =~ "Show User"
      assert html =~ user.email
    end

    test "updates user within modal", %{conn: conn, user: user} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/users/#{user}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit User"

      assert_patch(show_live, ~p"/admin/users/#{user}/show/edit")

      assert show_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#user-form", user: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/users/#{user}")

      html = render(show_live)
      assert html =~ "User updated successfully"
      assert html =~ "email_updated@example.com"
    end
  end
end
