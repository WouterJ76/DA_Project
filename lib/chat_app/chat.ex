defmodule TwitterClone.ChatApp.Chat do
    use GenServer

    @me __MODULE__

    defstruct chatroom: nil, chatlog: %{}

    def start_link(chatroom) do
        chatroom = chatroom || raise "No chatroom found \":chatroom\""
        GenServer.start_link(@me,chatroom, name: via_tuple(chatroom))
    end

    @impl true
    def init(args) do
        {:ok, args}
    end

    defp via_tuple(chatroom) do
        {:via, Registry, {TwitterClone.ChatApp.MyRegistry, {:chatsessie, chatroom}}}
    end
    
end