defmodule TwitterClone.ChatApp.Chat do
  use GenServer

  @me __MODULE__

  #########
  ## API ##
  #########

  def start_link(chatroom), do: GenServer.start_link(@me, chatroom, name: via_tuple(chatroom))

  def add_message(chatroom, sender, message) do
    get_id(chatroom)
    |> GenServer.cast({:add_message, sender, message})
  end

  def get_chatlog(chatroom) do
    get_id(chatroom)
    |> GenServer.call({:get_chatlog})
  end
  
  ###############
  ## Callbacks ##
  ###############

  @impl true
  def init(chatroom) do
    state = %{chatroom: chatroom, chatlog: []}
    {:ok, state}
  end

  @impl true
  def handle_call({:get_chatlog}, _, state) do
    {:reply, state.chatlog, state}
  end

  @impl true
  def handle_cast({:add_message, sender, message}, state) do
    new_state = %{state | chatlog: state.chatlog ++ [{sender, message}]}
    {:noreply, new_state}
  end

  ######################
  ## Helper functions ##
  ######################

  defp via_tuple(chatroom) do
    {:via, Registry, {TwitterClone.ChatApp.MyRegistry, {:chatsessie, chatroom}}}
  end

  defp get_id(chatroom) do
    [head | _] = Registry.lookup(TwitterClone.ChatApp.MyRegistry, {:chatsessie, chatroom})
    elem(head, 0)
  end
end