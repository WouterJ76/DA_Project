defmodule ChatSessie.Application do
    # See https://hexdocs.pm/elixir/Application.html
    # for more information on OTP Applications
    @moduledoc false
  
    use Application
  
    def start(_type, _args) do
      children = [
        # Starts a worker by calling: TwitterClone.Worker.start_link(arg)
        # {TwitterClone.Worker, arg}
        {Registry, keys: :unique, name: TwitterClone.MyRegistry},
        {DynamicSupervisor, strategy: :one_for_one, name: ChatSessie.UserDynSup},
        {TwitterClone.UserManager, []},
      ]
  
      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: TwitterClone.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
  