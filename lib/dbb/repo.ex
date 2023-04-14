defmodule Dbb.Repo do
  use Ecto.Repo,
    otp_app: :dbb,
    adapter: Ecto.Adapters.Postgres
end
