defmodule Dbb.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dbb.Content` context.
  """

  @doc """
  Generate a table.
  """
  def users_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{
      data: %{
        "name" => "some_name",
        "age" => 20
      },
      reference: "7488a646-e31f-11e4-aace-600308960662"
    })

    {:ok, table} = Dbb.Content.create_table("users", attrs)

    table
  end
end
