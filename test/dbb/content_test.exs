defmodule Dbb.ContentTest do
  use Dbb.DataCase

  alias Dbb.Content

  describe "table" do
    alias Dbb.Content.Table

    import Dbb.ContentFixtures

    @invalid_attrs nil

    test "list_table_records/1 returns all user_accounts" do
      user = users_fixture()
      assert Content.list_table_records("user_accounts", [], 0, 10) == [user]
    end

    test "get_table_record!/2 returns the table with given id" do
      users = users_fixture()
      assert Content.get_table_record!("user_accounts", users.id) == users
    end

    test "create_table/2 with valid data creates a user" do
      valid_attrs = %{}

      assert {:ok, %Table{} = user} = Content.create_table_record("user_accounts", valid_attrs)
      assert user.data == %{}
      assert user.schema == "user_accounts"
    end

    test "create_table/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Content.create_table_record("user_accounts", @invalid_attrs)
    end

    test "update_table/2 with valid data updates the user_accounts" do
      user = users_fixture()

      update_attrs = %{}

      assert {:ok, %Table{} = new_user} = Content.update_table_record(user, update_attrs)

      assert new_user.data == user.data
    end

    test "update_table/2 with invalid data returns error changeset" do
      user = users_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_table_record(user, @invalid_attrs)
      assert user == Content.get_table_record!("user_accounts", user.id)
    end

    test "delete_table/1 deletes the user_accounts" do
      user = users_fixture()
      assert {:ok, %Table{}} = Content.delete_table_record(user)

      assert_raise Ecto.NoResultsError, fn ->
        Content.get_table_record!("user_accounts", user.id)
      end
    end

    test "change_table/1 returns a user_accounts changeset" do
      user = users_fixture()
      assert %Ecto.Changeset{} = Content.change_table_record(user)
    end
  end
end
