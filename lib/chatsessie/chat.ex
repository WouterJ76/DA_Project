defmodule TwitterClone.ChatApp.Chat do
    use GenServer

    @me __MODULE__

    defstruct username1: nil, username2: nil, chatlog: %{}

    def start_link(args) do
        username1 = args[:username1] || raise "No username found \":username1\""
        username2 = args[:username2] || raise "No username found \":username2\""
        GenServer.start_link(@me,{username1, username2}, name: via_tuple(username1, username2))
    end

    @impl true
    def init(args) do
        {:ok, args}
    end

    defp via_tuple(username1, username2) do
        {:via, Registry, {TwitterClone.ChatApp.MyRegistry, {:chatsessie, username1, username2}}}
    end
    
end