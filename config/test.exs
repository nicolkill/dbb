import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :dbb, Dbb.Repo,
  username: System.get_env("POSTGRES_USERNAME"),
  password: System.get_env("POSTGRES_PASSWORD"),
  hostname: System.get_env("POSTGRES_HOSTNAME"),
  database: "#{System.get_env("POSTGRES_DATABASE")}_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dbb, DbbWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "o/QfYk5NOEdi2vp/L8lioLNgKGUGRD+gdBBC/Iq9MH9OxYyef8AE3Jhb9mtbTzLu",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
