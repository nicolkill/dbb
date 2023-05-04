defmodule Dbb.ContentTest do
  use Dbb.DataCase

  alias Dbb.Content

  describe "table" do
    alias Dbb.Content.Table

    import Dbb.ContentFixtures

    @invalid_attrs %{data: nil, deleted_at: nil, reference: nil, schema: nil}

    test "list_table/1 returns all users" do
      user = users_fixture()
      assert Content.list_table("users", [], 0, 10) == [user]
    end

    test "get_table!/2 returns the table with given id" do
      users = users_fixture()
      assert Content.get_table!("users", users.id) == users
    end

    test "create_table/2 with valid data creates a user" do
      valid_attrs = %{
        data: %{},
        reference: "7488a646-e31f-11e4-aace-600308960662",
        schema: "users"
      }

      assert {:ok, %Table{} = user} = Content.create_table("users", valid_attrs)
      assert user.data == %{}
      assert user.reference == "7488a646-e31f-11e4-aace-600308960662"
      assert user.schema == "users"
    end

    test "create_table/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_table("users", @invalid_attrs)
    end

    test "update_table/2 with valid data updates the users" do
      user = users_fixture()
      update_attrs = %{
        data: %{},
        reference: "7488a646-e31f-11e4-aace-600308960668"
      }

      assert {:ok, %Table{} = user} = Content.update_table(user, update_attrs)
      assert user.data == %{}
      assert user.reference == "7488a646-e31f-11e4-aace-600308960668"
    end

    test "update_table/2 with invalid data returns error changeset" do
      user = users_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_table(user, @invalid_attrs)
      assert user == Content.get_table!("users", user.id)
    end

    test "delete_table/1 deletes the users" do
      user = users_fixture()
      assert {:ok, %Table{}} = Content.delete_table(user)
      assert_raise Ecto.NoResultsError, fn -> Content.get_table!("users", user.id) end
    end

    test "change_table/1 returns a users changeset" do
      user = users_fixture()
      assert %Ecto.Changeset{} = Content.change_table(user)
    end
  end
end
