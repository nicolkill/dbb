defmodule DbbWeb.Page.PageControllerTest do
  use DbbWeb.ConnCase

  import Phoenix.LiveViewTest
  import Dbb.ContentFixtures

  describe "GET /users" do
    test "show empty state screen", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users")

      view = element(view, "span.block.w-full.bg-gray-100")

      assert render(view) =~ "Not data"
    end

    test "show users data", %{conn: conn} do
      %{users: [user | _rest]} = create_users(nil)
      {:ok, view, _html} = live(conn, ~p"/users")

      view = element(view, "table.table-auto.w-full tbody tr:first-child()")

      assert render(view) =~ user.data["name"]
    end

    #    test "handles delete on UI", %{conn: conn} do
    #      %{users: [user | _rest]} = create_users(nil)
    #      {:ok, view, _html} = live(conn, ~p"/users")
    #
    #      view
    #      |> element("table.table-auto.w-full tbody tr button#delete_#{user.id}_button")
    #      |> render_click()
    #
    #      delete_params = %{"row-id" => user.id}
    #      assert_push_event view, "delete", delete_params
    #
    #      assert render_async(view) =~ "asdf"
    #    end

    test "handles edit redirect", %{conn: conn} do
      %{users: [user | _rest]} = create_users(nil)
      {:ok, view, _html} = live(conn, ~p"/users")

      {:ok, view, _html} =
        view
        |> element("table.table-auto.w-full tbody tr a#edit_#{user.id}_button")
        |> render_click()
        |> follow_redirect(conn)

      render(view) =~ "Update Users record"
    end
  end

  defp create_users(_) do
    user1 = users_fixture(%{"name" => "jhon", "age" => 20})
    user2 = users_fixture(%{"name" => "jim", "age" => 22})
    user3 = users_fixture(%{"name" => "mike"})

    %{users: [user1, user2, user3]}
  end
end
