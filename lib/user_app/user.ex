defmodule TwitterClone.UserApp.User do
    use GenServer

    @me __MODULE__

    defstruct username: nil

    def start_link(args) do
        username = args[:username] || raise "No username found \":username\""
        GenServer.start_link(@me,username, name: via_tuple(username))
    end

    @impl true
    def init(args) do
        {:ok, args}
    end

    defp via_tuple(username) do
        {:via, Registry, {TwitterClone.UserApp.MyRegistry, {:user, username}}}
    end
end