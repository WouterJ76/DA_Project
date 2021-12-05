defmodule UserApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: UserApp.Worker.start_link(arg)
      # {UserApp.Worker, arg}
      {Registry, keys: :unique, name: UserApp.MyRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: UserApp.UserDynSup},
      {UserApp.UserManager, []},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UserApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
