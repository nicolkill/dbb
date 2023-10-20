defmodule Dbb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # manual init area
    Dbb.Cache.init()
    Dbb.Schema.load_config()
    Dbb.Release.migrate()

    children = [
      DbbWeb.Telemetry,
      Dbb.Repo,
      {DNSCluster, query: Application.get_env(:dbb, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Dbb.PubSub},
      # Start a worker by calling: Dbb.Worker.start_link(arg)
      # {Dbb.Worker, arg},
      # Start to serve requests, typically the last entry
      DbbWeb.Endpoint
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
