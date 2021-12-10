defmodule TwitterClone do
  def start(_type, _args) do
    children = [
      TwitterClone.UserApp.Supervisor,
      TwitterClone.ChatApp.Supervisor,
      TwitterClone.PostApp.Posts
    ]

    opts = [strategy: :one_for_one, name: TwitterClone.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
