defmodule TwitterClone.ChatApp.ChatManager do
    use GenServer

    alias TwitterClone.ChatApp.{Chat, ChatDynSup}

    @me __MODULE__
    defstruct chatrooms: %{}

    def start_link(args) do
        GenServer.start_link(@me, args, name: @me)
    end

    def create_chat(chatroom) do
        GenServer.call(@me, {:create_chat, chatroom})
    end

    # def send_message(username2, message) do
    #     GenServer.call(@me, {:send_message, username2, message})
    # end

    def list_chats(), do: GenServer.call(@me, :list_chats)

    @impl true
    def init(_args), do: {:ok, %@me{}}

    @impl true
    def handle_call({:test, chatroom}, _from, %@me{} = state) do
        # case Map.has_key?(state.chatrooms, chatroom) do
        # true ->
        #     {:reply, {:error, :already_exists}, state}

        # false ->
        #     DynamicSupervisor.start_child(ChatDynSup, {Chat, [chatroom]})
        #     # TwitterClone.ChatApp.MessagePublisher.start_link(username2)
        #     # TwitterClone.UserApp.MessageConsumer.start_link(username2)
        #     # TwitterClone.ChatApp.MessagePublisher.send_message(message)
        #     DynamicSupervisor.start_child(ChatDynSup, {TwitterClone.ChatApp.MessagePublisher, username2})
        #     DynamicSupervisor.start_child(TwitterClone.UserApp.UserDynSup, {TwitterClone.UserApp.MessageConsumer, username2})
        #     new_chatsessie = Map.put_new(state.chatrooms, {username1, username2}, %{username1: username1, username2: username2})
        #     {:reply, :chatroom_created, %{state | chatrooms: new_chatsessie}}
        # end
    end

    @impl true
    def handle_call({:create_chat, chatroom}, _from, state) do
        case Map.has_key?(state.chatrooms, chatroom) do
        true ->
            {:reply, {:error, :already_exists}, state}

        false ->
            DynamicSupervisor.start_child(ChatDynSup, {Chat, [chatroom]})
            Map.put_new(state.chatrooms, chatroom, %{chatroom: chatroom})
        end
        {:reply, :message_send, state}
    end

    @impl true
    def handle_call(:list_Chats, _from, state) do
        {:reply, state.chatrooms, state}
    end
end