# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :dbb,
  ecto_repos: [Dbb.Repo],
  generators: [binary_id: true]

allowed_sites =
  System.get_env("ALLOWED_SITES") ||
    "*"
    |> String.split(",")

config :cors_plug,
  origin: allowed_sites

# Configures the endpoint
config :dbb, DbbWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: DbbWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Dbb.PubSub,
  live_view: [signing_salt: "PVwpobeo"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :dbb, :schema_config,
  file: System.get_env("CONFIG_SCHEMA")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
