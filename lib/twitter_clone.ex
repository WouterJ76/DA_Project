defmodule TwitterClone do
  use Application
  
  def start(_type, _args) do
    children = [
      #UserApp
      TwitterClone.UserApp.Supervisor,
      TwitterClone.ChatApp.Supervisor
    ]

    opts = [strategy: :one_for_one, name: TwitterClone.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
