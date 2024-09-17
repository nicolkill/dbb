defmodule Dbb.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:dbb_admin_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string
      add :email, :string
      add :password, :string
      add :first_name, :string
      add :last_name, :string
      add :deleted_at, :naive_datetime
      add :roles, {:array, :string}

      timestamps(type: :utc_datetime)
    end

    create index(:dbb_admin_users, [:email, :username], unique: true)
  end
end
