defmodule Dbb.AccountsTest do
  use Dbb.DataCase

  alias Dbb.Accounts

  describe "users" do
    alias Dbb.Accounts.User

    import Dbb.AccountsFixtures

    @invalid_attrs %{
      email: "invalid_mail",
      first_name: nil,
      last_name: nil,
      password: "invalid",
      username: nil
    }

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{
        email: "email@example.com",
        first_name: "some first_name",
        last_name: "some last_name",
        password: "some password",
        username: "some username"
      }

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == "email@example.com"
      assert user.first_name == "some first_name"
      assert user.last_name == "some last_name"
      assert user.username == "some username"
      assert Bcrypt.verify_pass("some password", user.password)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()

      update_attrs = %{
        email: "email_updated@example.com",
        first_name: "some updated first_name",
        last_name: "some updated last_name",
        password: "some updated password",
        username: "some updated username"
      }

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.email == "email_updated@example.com"
      assert user.first_name == "some updated first_name"
      assert user.last_name == "some updated last_name"
      assert user.username == "some updated username"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "login_email/2 returns the user with correct password" do
      password = "my_password"

      user =
        %{password: password}
        |> user_fixture()

      assert %User{email: email} = Accounts.login_email(user.email, password)
      assert user.email == email
    end

    test "login_username/2 returns the user with correct password" do
      password = "my_password"

      user =
        %{password: password}
        |> user_fixture()

      assert %User{email: email} = Accounts.login_username(user.username, password)
      assert user.email == email
    end

    test "login_username/2 returns nil with wrong password" do
      password = "my_password"
      user = user_fixture()
      refute Accounts.login_username(user.username, password)
    end
  end
end
