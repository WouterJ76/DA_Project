defmodule TwitterClone.UserApp.ChatSessiePublisher do
    use GenServer
    require IEx
    require Logger

    @channel :chat_app_channel
    @exchange "chatapp-server"
    @queue "chat-sessie-queue"
  
    @me __MODULE__
  
    @enforce_keys [:channel]
    defstruct [:channel]
  
    # ## API ##
  
    def start_link(_args \\ []), do: GenServer.start_link(@me, :no_opts, name: @me)
    def start_chat(user1, user2), do: GenServer.call(@me, {:start_chat, user1, user2})
    def get_chatlog({user1, user2}), do: GenServer.call(@me, {:get_chatlog, {user1, user2}})
    def send_message({user1, user2}, message), do: GenServer.call(@me, {:send_message, {user1, user2}})
  
    # ## Callbacks ##
  
    # @impl true
    def init(:no_opts) do
        {:ok, amqp_channel} = AMQP.Application.get_channel(@channel)
        state = %@me{channel: amqp_channel}
        rabbitmq_setup(state)
    
        {:ok, state}
    end
  
    @impl true
    def handle_call({:start_chat, user1, user2}, _, %@me{channel: c} = state) do
        payload = Jason.encode!(%{command: "create", user1: user1, user2: user2})
        :ok = AMQP.Basic.publish(c, @exchange, @queue, payload)
        {:reply, :chat_started, state}
    end

    def handle_call({:get_chatlog, {user1, user2}}, _, %@me{channel: c} = state) do
        payload = Jason.encode!(%{command: "get", chatroom: {user1, user2}})
        :ok = AMQP.Basic.publish(c, @exchange, @queue, payload)
        {:reply, :chat_started, state}
    end

    def handle_call({:send_message, {user1, user2}}, _, %@me{channel: c} = state) do
        payload = Jason.encode!(%{command: "get", chatroom: {user1, user2}})
        :ok = AMQP.Basic.publish(c, @exchange, @queue, payload)
        {:reply, :chat_started, state}
    end
  
    ## Helper functions ##
  
    defp rabbitmq_setup(%@me{} = state) do
        # Create exchange, queue and bind them.
        :ok = AMQP.Exchange.declare(state.channel, @exchange, :direct)
        {:ok, _consumer_and_msg_info} = AMQP.Queue.declare(state.channel, @queue)
        :ok = AMQP.Queue.bind(state.channel, @queue, @exchange, routing_key: @queue)
    end
end