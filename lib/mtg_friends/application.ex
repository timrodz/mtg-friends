defmodule MtgFriends.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MtgFriendsWeb.Telemetry,
      # Start the Ecto repository
      MtgFriends.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: MtgFriends.PubSub},
      # Start Finch
      {Finch, name: MtgFriends.Finch},
      # Start the Endpoint (http/https)
      MtgFriendsWeb.Endpoint
      # Start a worker by calling: MtgFriends.Worker.start_link(arg)
      # {MtgFriends.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MtgFriends.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MtgFriendsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
