defmodule TwitterClone.ChatApp.ChatManager do
    use GenServer

    alias TwitterClone.ChatApp.{Chat, ChatDynSup}

    @me __MODULE__

    #########
    ## API ##
    #########

    def start_link(args) do
        GenServer.start_link(@me, args, name: @me)
    end

    def create_chatroom(chatroom) do
        GenServer.call(@me, {:create_chatroom, chatroom})
    end

    def list_chatrooms(), do: GenServer.call(@me, :list_chatrooms)

    ###############
    ## Callbacks ##
    ###############

    @impl true
    def init(_args) do
        state = %{chatrooms: []}
        {:ok, state}
    end

    # @impl true
    # def handle_call({:test, chatroom}, _from, %@me{} = state) do
    #     case Map.has_key?(state.chatrooms, chatroom) do
    #     true ->
    #         {:reply, {:error, :already_exists}, state}

    #     false ->
    #         DynamicSupervisor.start_child(ChatDynSup, {TwitterClone.ChatApp.MessagePublisher, username2})
    #         DynamicSupervisor.start_child(TwitterClone.UserApp.UserDynSup, {TwitterClone.UserApp.MessageConsumer, username2})
    #         new_chatsessie = Map.put_new(state.chatrooms, {username1, username2}, %{username1: username1, username2: username2})
    #         {:reply, :chatroom_created, %{state | chatrooms: new_chatsessie}}
    #     end
    # end

    @impl true
    def handle_call({:create_chatroom, chatroom}, _from, state) do
        case Enum.member?(state.chatrooms, chatroom) do
        true ->
            {:reply, {:error, :already_exists}, state}

        false ->
            DynamicSupervisor.start_child(ChatDynSup, {Chat, chatroom})
            new_state = %{state | chatrooms: [chatroom | state.chatrooms]}
            {:reply, :created_chatroom, new_state}
        end
    end

    @impl true
    def handle_call(:list_chatrooms, _from, state) do
        {:reply, state.chatrooms, state}
    end
end