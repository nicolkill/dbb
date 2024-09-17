defmodule Dbb.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @required_fields [:username, :email, :password]
  @fields @required_fields ++ [:first_name, :last_name, :roles]
  @change_password_fields [:password]
  @update_fields @fields -- @change_password_fields
  @soft_delete_fields [:deleted_at]

  schema "dbb_admin_users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :password, :string
    field :username, :string
    field :roles, {:array, :string}

    # soft delete field
    field :deleted_at, :naive_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, @update_fields)
    |> validate_format(:email, ~r/@/)
  end

  def changeset_change_password(table, attrs) do
    table
    |> cast(attrs, @change_password_fields)
    |> validate_required(@change_password_fields)
  end

  def changeset_delete(table, attrs) do
    table
    |> cast(attrs, @soft_delete_fields)
    |> validate_required(@soft_delete_fields)
  end
end
