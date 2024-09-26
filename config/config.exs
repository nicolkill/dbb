# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :dbb,
  ecto_repos: [Dbb.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :dbb, DbbWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: DbbWeb.ErrorHTML, json: DbbWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Dbb.PubSub,
  live_view: [signing_salt: "jqONnOxx"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :tesla, adapter: Tesla.Adapter.Hackney

config :dbb, Dbb.Accounts.Guardian,
  issuer: "dbb",
  secret_key:
    System.get_env("AUTH_SECRET_KEY") ||
      "TFPxxJeL3/cLiv46/1kCCciZHsuwa8JAmY2klZkMixEsVC7kfg8j3oWHhUz6HOBq"

config :troll_bridge, config: Dbb.Accounts.TrollBridge

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
