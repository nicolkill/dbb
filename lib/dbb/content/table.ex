defmodule Dbb.Content.Table do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @required_fields [:schema, :reference, :data]
  @fields @required_fields
  @soft_delete_fields [:deleted_at]

  schema "table" do
    field :data, :map
    field :reference, Ecto.UUID
    field :schema, :string

    # soft delete field
    field :deleted_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(table, attrs) do
    table
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
  def changeset_delete(table, attrs) do
    table
    |> cast(attrs, @soft_delete_fields)
    |> validate_required(@soft_delete_fields)
  end
end
