defmodule TwitterClone.ChatApp.MessagePublisher do
    use GenServer
    require IEx
    require Logger

    @channel :chat_app_channel
    @exchange "user-server"
  
    @me __MODULE__
  
    @enforce_keys [:channel]
    defstruct [:channel, :queue]
  
    # ## API ##
  
    def start_link(username), do: GenServer.start_link(@me, username, name: String.to_atom(username))
    def send_chatlog({user1, user2}), do: GenServer.call(@me, {:get_chatlog, {user1, user2}})
    def send_message(message), do: GenServer.call(@me, {:send_message, message})
  
    # ## Callbacks ##
  
    @impl true
    def init(username) do
        {:ok, amqp_channel} = AMQP.Application.get_channel(@channel)
        state = %@me{channel: amqp_channel, queue: username}
        rabbitmq_setup(state)
    
        {:ok, state}
    end
  
    @impl true
    def handle_call({:start_chat, user1, user2}, _, %@me{channel: c} = state) do
        payload = Jason.encode!(%{command: "create", user1: user1, user2: user2})
        :ok = AMQP.Basic.publish(c, @exchange, state.queue, payload)
        {:reply, :chat_started, state}
    end

    def handle_call({:get_chatlog, {user1, user2}}, _, %@me{channel: c} = state) do
        payload = Jason.encode!(%{command: "get", chatroom: {user1, user2}})
        :ok = AMQP.Basic.publish(c, @exchange, state.queue, payload)
        {:reply, :chat_started, state}
    end

    def handle_call({:send_message, message}, _, %@me{channel: c} = state) do
        payload = Jason.encode!(%{command: "get", chatroom: message})
        :ok = AMQP.Basic.publish(c, @exchange, state.queue, payload)
        {:reply, :chat_started, state}
    end
  
    ## Helper functions ##
  
    defp rabbitmq_setup(%@me{} = state) do
        # Create exchange, queue and bind them.
        :ok = AMQP.Exchange.declare(state.channel, @exchange, :direct)
        {:ok, _consumer_and_msg_info} = AMQP.Queue.declare(state.channel, state.queue)
        :ok = AMQP.Queue.bind(state.channel, state.queue, @exchange, routing_key: state.queue)
    end
end