defmodule TwitterClone.ChatApp.ChatManager do
    use GenServer

    alias TwitterClone.ChatApp.{Chat, ChatDynSup, NotificationPublisher}
    alias TwitterClone.UserApp.{UserDynSup, NotificationConsumer}

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

    def start_publisher_consumer(chatroom) do
        GenServer.call(@me, {:start_publisher_consumer, chatroom})
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

    @impl true
    def handle_call({:start_publisher_consumer, chatroom}, _from, state) do
        DynamicSupervisor.start_child(ChatDynSup, {NotificationPublisher, chatroom})
        DynamicSupervisor.start_child(UserDynSup, {NotificationConsumer, chatroom})
        {:reply, :notification_service_created, state}
    end

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