defmodule Dbb.Content.Table do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "table" do
    field :data, :map
    field :deleted_at, :naive_datetime
    field :reference, Ecto.UUID
    field :schema, :string

    timestamps()
  end

  @doc false
  def changeset(table, attrs) do
    table
    |> cast(attrs, [:schema, :reference, :data, :deleted_at])
    |> validate_required([:schema, :reference, :data, :deleted_at])
  end
end
