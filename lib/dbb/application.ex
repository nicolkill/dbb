defmodule Dbb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # manual init area
    Dbb.Cache.init()
    Dbb.Release.migrate()

    children = [
      # Start the Telemetry supervisor
      DbbWeb.Telemetry,
      # Start the Ecto repository
      Dbb.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Dbb.PubSub},
      # Start the Endpoint (http/https)
      DbbWeb.Endpoint
      # Start a worker by calling: Dbb.Worker.start_link(arg)
      # {Dbb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dbb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DbbWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
