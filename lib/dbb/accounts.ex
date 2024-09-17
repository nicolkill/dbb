defmodule Dbb.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Dbb.Repo

  alias Dbb.Accounts.User

  defp salt, do: Application.get_env(:dbb, Dbb.Accounts.Guardian)[:auth_salt]

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{})

  def create_user(%{"password" => password} = attrs) do
    attrs = Map.put(attrs, "password", hash_password(password))

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_user(attrs) do
    attrs
    |> Dbb.Utils.purify_params()
    |> create_user()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def login_email(email, password) do
    User
    |> where(email: ^email)
    |> Repo.one()
    |> verify_password(password)
  end

  def login_username(username, password) do
    User
    |> where(username: ^username)
    |> Repo.one()
    |> verify_password(password)
  end

  defp hash_password(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  defp verify_password(nil, _),
    do: nil

  defp verify_password(%User{} = user, password) do
    if Bcrypt.verify_pass(password, user.password) do
      user
    else
      nil
    end
  end
end
