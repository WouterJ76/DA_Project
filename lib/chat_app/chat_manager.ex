defmodule TwitterClone.ChatApp.ChatManager do
    use GenServer

    alias TwitterClone.ChatApp.{Chat, ChatDynSup}

    @me __MODULE__
    defstruct chatsessies: %{}

    def start_link(args) do
        GenServer.start_link(@me, args, name: @me)
    end

    def add_chat(username1, username2) do
        GenServer.call(@me, {:create_chat, username1, username2})
    end

    def send_message(username2, message) do
        GenServer.call(@me, {:send_message, username2, message})
    end

    def list_chats(), do: GenServer.call(@me, :list_chats)

    @impl true
    def init(_args), do: {:ok, %@me{}}

    # @impl true
    def handle_cast() do
        
    end

    @impl true
    def handle_call({:create_chat, username1, username2}, _from, %@me{} = state) do
        case Map.has_key?(state.chatsessies, {username1, username2}) do
        true ->
            {:reply, {:error, :already_exists}, state}

        false ->
            response = DynamicSupervisor.start_child(ChatDynSup, {Chat, [username1: username1, username2: username2]})
            TwitterClone.ChatApp.MessagePublisher.start_link(username2)
            TwitterClone.UserApp.MessageConsumer.start_link(username2)
            # TwitterClone.ChatApp.MessagePublisher.send_message(message)
            # DynamicSupervisor.start_child(ChatDynSup, {TwitterClone.ChatApp.MessagePublisher, username2})
            # DynamicSupervisor.start_child(TwitterClone.UserApp.UserDynSup, {TwitterClone.UserApp.MessageConsumer, username2})
            new_chatsessie = Map.put_new(state.chatsessies, {username1, username2}, %{username1: username1, username2: username2})
            {:reply, response, %{state | chatsessies: new_chatsessie}}
        end
    end

    @impl true
    def handle_call({:send_message, username2, message}, _from, state) do
        TwitterClone.ChatApp.MessagePublisher.start_link(username2)
        TwitterClone.ChatApp.MessagePublisher.send_message(message)
        {:reply, :message_send, state}
    end

    @impl true
    def handle_call(:list_Chats, _from, state) do
        {:reply, state.chatsessies, state}
    end

    # @impl true
    def handle_continue() do
        
    end
end