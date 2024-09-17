defmodule Dbb.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dbb.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "email@example.com",
        first_name: "some first_name",
        last_name: "some last_name",
        password: "some password",
        username: "some username"
      })
      |> Dbb.Accounts.create_user()

    user
  end
end
