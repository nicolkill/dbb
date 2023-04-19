defmodule Dbb.ContentTest do
  use Dbb.DataCase

  alias Dbb.Content

  describe "table" do
    alias Dbb.Content.Table

    import Dbb.ContentFixtures

    @invalid_attrs %{data: nil, deleted_at: nil, reference: nil, schema: nil}

    test "list_table/0 returns all table" do
      table = table_fixture()
      assert Content.list_table() == [table]
    end

    test "get_table!/1 returns the table with given id" do
      table = table_fixture()
      assert Content.get_table!(table.id) == table
    end

    test "create_table/1 with valid data creates a table" do
      valid_attrs = %{data: %{}, deleted_at: ~N[2023-04-17 23:57:00], reference: "7488a646-e31f-11e4-aace-600308960662", schema: "some schema"}

      assert {:ok, %Table{} = table} = Content.create_table(valid_attrs)
      assert table.data == %{}
      assert table.deleted_at == ~N[2023-04-17 23:57:00]
      assert table.reference == "7488a646-e31f-11e4-aace-600308960662"
      assert table.schema == "some schema"
    end

    test "create_table/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_table(@invalid_attrs)
    end

    test "update_table/2 with valid data updates the table" do
      table = table_fixture()
      update_attrs = %{data: %{}, deleted_at: ~N[2023-04-18 23:57:00], reference: "7488a646-e31f-11e4-aace-600308960668", schema: "some updated schema"}

      assert {:ok, %Table{} = table} = Content.update_table(table, update_attrs)
      assert table.data == %{}
      assert table.deleted_at == ~N[2023-04-18 23:57:00]
      assert table.reference == "7488a646-e31f-11e4-aace-600308960668"
      assert table.schema == "some updated schema"
    end

    test "update_table/2 with invalid data returns error changeset" do
      table = table_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_table(table, @invalid_attrs)
      assert table == Content.get_table!(table.id)
    end

    test "delete_table/1 deletes the table" do
      table = table_fixture()
      assert {:ok, %Table{}} = Content.delete_table(table)
      assert_raise Ecto.NoResultsError, fn -> Content.get_table!(table.id) end
    end

    test "change_table/1 returns a table changeset" do
      table = table_fixture()
      assert %Ecto.Changeset{} = Content.change_table(table)
    end
  end
end
