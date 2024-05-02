defmodule Dbb.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dbb.Content` context.
  """

  @doc """
  Generate a table element with schema of users.
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

  @doc """
  Generate a table element with schema of orders.
  """
  def orders_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "estimated_delivery_time" => "2024-04-24 00:00:00"
      })

    {:ok, table} = Dbb.Content.create_table_record("orders", attrs)

    table
  end

  @doc """
  Generate a table element with schema of products.
  """
  def order_product_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "order_id" => "this_must_be_from_attrs",
        "product_id" => "this_must_be_from_attrs"
      })

    {:ok, table} = Dbb.Content.create_table_record("order_product", attrs)

    table
  end

  @doc """
  Generate a table element with schema of products.
  """
  def products_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "name" => "product duck",
        "description" => "this product represents a duck on sale"
      })

    {:ok, table} = Dbb.Content.create_table_record("products", attrs)

    table
  end
end
