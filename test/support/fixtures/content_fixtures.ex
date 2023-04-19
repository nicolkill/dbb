defmodule Dbb.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dbb.Content` context.
  """

  @doc """
  Generate a table.
  """
  def table_fixture(attrs \\ %{}) do
    {:ok, table} =
      attrs
      |> Enum.into(%{
        data: %{},
        deleted_at: ~N[2023-04-17 23:57:00],
        reference: "7488a646-e31f-11e4-aace-600308960662",
        schema: "some schema"
      })
      |> Dbb.Content.create_table()

    table
  end
end
