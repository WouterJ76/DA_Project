defmodule TwitterClone.UserApp.UserManager do
  use GenServer

  alias TwitterClone.UserApp.{User, UserDynSup, ChatroomPublisher}
  alias TwitterClone.ChatApp.{ChatDynSup, ChatroomConsumer}

  @me __MODULE__

  #########
  ## API ##
  #########

  def start_link(_args) do
    GenServer.start_link(@me, :no_args, name: @me)
  end

  def create_user(username) do
    GenServer.call(@me, {:create_user, username})
  end

  def start_chatroom(user1, user2) do
    GenServer.call(@me, {:start_chatroom, user1, user2})
  end

  def list_users(), do: GenServer.call(@me, :list_users)
  
  def list_chatrooms(), do: GenServer.call(@me, :list_chatrooms)

  ###############
  ## Callbacks ##
  ###############

  @impl true
  def init(_args) do
    state = %{users: [], chatrooms: []}
    {:ok, state}
  end

  @impl true
  def handle_call({:create_user, username}, _from, state) do
    case Enum.member?(state.users, username) do
    true ->
      {:reply, {:error, :already_exists}, state}

    false ->
      DynamicSupervisor.start_child(UserDynSup, {User, [username]})
      new_state = %{state | users: [username | state.users]}
      {:reply, "created user: #{username}", new_state}
    end
  end

  @impl true
  def handle_call({:start_chatroom, user1, user2}, _from, state) do
    if Enum.member?(state.users, user1) && Enum.member?(state.users, user2) do
      chatroom = Enum.reduce([user1, user2], fn user, acc -> "#{acc}-#{user}" end)
      chatroom2 = Enum.reduce([user1, user2], fn user, acc -> "#{user}-#{acc}" end)
      case Enum.member?(state.chatrooms, chatroom) || Enum.member?(state.chatrooms, chatroom2) do
      true ->
        case Enum.member?(state.chatrooms, chatroom) do
          true ->
            {:reply, chatroom, state}
                  
          false ->
            {:reply, chatroom2, state}
        end

      false ->
        DynamicSupervisor.start_child(UserDynSup, {ChatroomPublisher, chatroom})
        DynamicSupervisor.start_child(ChatDynSup, {ChatroomConsumer, chatroom})
        chatroom = ChatroomPublisher.create_chatroom(chatroom)
        new_state = %{state | chatrooms: [chatroom | state.chatrooms]}
        {:reply, chatroom, new_state}
      end
    else
      {:reply, {:error, :user_not_exists}, state}
    end
  end

  @impl true
  def handle_call(:list_users, _from, state) do
    {:reply, state.users, state}
  end

  @impl true
  def handle_call(:list_chatrooms, _from, state) do
    {:reply, state.chatrooms, state}
  end
end