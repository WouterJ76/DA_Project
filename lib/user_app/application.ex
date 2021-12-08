defmodule TwitterClone.UserApp.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, keys: :unique, name: TwitterClone.UserApp.MyRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: TwitterClone.UserApp.UserDynSup},
      {TwitterClone.UserApp.UserManager, []},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
