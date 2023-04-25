defmodule Dbb.Repo.Migrations.CreateTable do
  use Ecto.Migration

  def change do
    create table(:table, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :schema, :string
      add :reference, :uuid, null: true
      add :data, :map
      add :deleted_at, :naive_datetime

      timestamps()
    end
  end
end
