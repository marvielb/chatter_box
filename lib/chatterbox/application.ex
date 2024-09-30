defmodule Chatterbox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChatterboxWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:chatterbox, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Chatterbox.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Chatterbox.Finch},
      # Start a worker by calling: Chatterbox.Worker.start_link(arg)
      # {Chatterbox.Worker, arg},
      # Start to serve requests, typically the last entry
      ChatterboxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chatterbox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChatterboxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
