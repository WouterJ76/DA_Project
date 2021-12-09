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
  
    def start_link(username), do: GenServer.start_link(@me, username, name: via_tuple(username))

    def send_chatlog({sender, receiver}) do
        get_id(receiver)
        |> GenServer.call(@me, {:get_chatlog, {sender, receiver}})
    end

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
    def handle_call({:start_chat, sender, receiver}, _, %@me{channel: c} = state) do
        payload = Jason.encode!(%{command: "create", sender: sender, receiver: receiver})
        :ok = AMQP.Basic.publish(c, @exchange, state.queue, payload)
        {:reply, :chat_started, state}
    end

    def handle_call({:get_chatlog, {sender, receiver}}, _, %@me{channel: c} = state) do
        payload = Jason.encode!(%{command: "get", chatroom: {sender, receiver}})
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

    defp via_tuple(username) do
        {:via, Registry, {TwitterClone.ChatApp.MyRegistry, {:username, username}}}
    end

    defp get_id(username) do
        [head | _] = Registry.lookup(TwitterClone.ChatApp.MyRegistry, {:username, username})
        elem(head, 0)
    end
end