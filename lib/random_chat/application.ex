defmodule RandomChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    OpentelemetryBandit.setup()
    OpentelemetryPhoenix.setup(adapter: :bandit)

    children = [
      RandomChatWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:random_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RandomChat.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: RandomChat.Finch},
      # Start a worker by calling: RandomChat.Worker.start_link(arg)
      # {RandomChat.Worker, arg},
      {RandomChat.Queue, :ok},
      # Start to serve requests, typically the last entry
      {Registry, keys: :unique, name: RandomChat.RoomRegistry},
      RandomChatWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RandomChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RandomChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
