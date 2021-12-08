defmodule TwitterClone.UserApp.ChatSessiePublisher do
    use GenServer
    require IEx
    require Logger

    alias TwitterClone.UserApp.ChatSessiePublisher, as: ChatSessiePublisher

    @channel :chat_app_channel
    @exchange "chatapp-server"
    @me __MODULE__
  
    @enforce_keys [:channel]
    defstruct [:channel, :queue]
  
    def start_link(chatroom), do: GenServer.start_link(@me, chatroom, name: String.to_atom("publisher: #{chatroom}"))
    def get_chatlog(), do: GenServer.call(@me, {:get_chatlog})
    def send_message(message), do: GenServer.call(@me, {:send_message, message})
  
    @impl true
    def init(chatroom) do
        {:ok, amqp_channel} = AMQP.Application.get_channel(@channel)
        state = %@me{channel: amqp_channel, queue: chatroom}
        rabbitmq_setup(state)
        payload = Jason.encode!(%{command: "create_chatlog", chatroom: state.queue})
        :ok = AMQP.Basic.publish(state.channel, @exchange, state.queue, payload)

        {:ok, state}
    end

    @impl true
    def handle_call({:get_chatlog}, _, %@me{channel: c, queue: q} = state) do
        payload = Jason.encode!(%{command: "get_chatlog", chatroom: q})
        :ok = AMQP.Basic.publish(c, @exchange, q, payload)
        {:reply, :chat_started, state}
    end

    @impl true
    def handle_call({:send_message, message}, _, %@me{channel: c, queue: q} = state) do
        payload = Jason.encode!(%{command: "send_message", message: message})
        :ok = AMQP.Basic.publish(c, @exchange, q, payload)
        {:reply, :chatroom_init, state}
    end
  
    ## Helper functions ##
  
    defp rabbitmq_setup(%@me{} = state) do
        # Create exchange, queue and bind them.
        :ok = AMQP.Exchange.declare(state.channel, @exchange, :direct)
        {:ok, _consumer_and_msg_info} = AMQP.Queue.declare(state.channel, state.queue)
        :ok = AMQP.Queue.bind(state.channel, state.queue, @exchange, routing_key: state.queue)
    end
end