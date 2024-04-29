defmodule Dbb.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dbb.Content` context.
  """

  @doc """
  Generate a table.
  """
  def users_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "name" => "some_name",
        "male" => true,
        "birth" => "2024-04-24 00:00:00",
        "flags" => ["super-flag"]
      })

    {:ok, table} = Dbb.Content.create_table_record("users", attrs)

    table
  end
end
