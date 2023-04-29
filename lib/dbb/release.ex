defmodule Dbb.Release do
  @moduledoc """
  A set of functions to eval from the running release.
  """
  @app :dbb

  require Logger

  # exclude some repos from migrations since
  # we are not owner of them
  @exclude_repos []

  def migrate do
    repos()
    |> IO.inspect(label: "repos")
    |> Enum.each(&apply_migrations/1)
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)

    Application.fetch_env!(@app, :ecto_repos)
    |> Enum.reject(fn repo -> repo in @exclude_repos end)
  end

  defp apply_migrations(repo) do
    {:ok, migrations, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.migrations(&1))

    migrations
    |> Enum.filter(fn
      {:down, _, _} -> true
      {:up, _, _} -> false
    end)
    |> case do
         [] ->
           Logger.info("there's no pending migrations for repo #{inspect(repo)}")

         pending ->
           Logger.info(
             "there's pending migrations for repo #{inspect(repo)}, pending migrations: #{
               inspect(pending)
             }"
           )

           {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
       end
  end
end
