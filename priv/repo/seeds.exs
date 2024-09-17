# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Dbb.Repo.insert!(%Dbb.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Dbb.Accounts.create_user(%{
  "username" => "admin",
  "email" => "admin@admin.com",
  "password" => "pass"
})
