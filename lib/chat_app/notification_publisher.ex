defmodule TwitterClone.ChatApp.MessagePublisher do
    use GenServer

    alias TwitterClone.ChatApp.{MyRegistry}

    @channel :chat_app_channel
    @exchange "message-server"
  
    @me __MODULE__
  
    @enforce_keys [:channel]
    defstruct [:channel, :queue]
  
    #########
    ## API ##
    #########
  
    def start_link(chatroom), do: GenServer.start_link(@me, chatroom, name: via_tuple(chatroom))

    def send_message(chatroom, message) do
        get_id(chatroom)
        |> GenServer.call(@me, {:send_message, message})
    end

    ###############
    ## Callbacks ##
    ###############
  
    @impl true
    def init(username) do
        {:ok, amqp_channel} = AMQP.Application.get_channel(@channel)
        state = %@me{channel: amqp_channel, queue: username}
        rabbitmq_setup(state)
    
        {:ok, state}
    end
  
    @impl true
    def handle_call({:send_message, message}, _, %@me{channel: c} = state) do
        payload = Jason.encode!(%{command: "get", chatroom: message})
        :ok = AMQP.Basic.publish(c, @exchange, state.queue, payload)
        {:reply, :chat_started, state}
    end
  
    ######################
    ## Helper functions ##
    ######################
  
    defp rabbitmq_setup(%@me{} = state) do
        # Create exchange, queue and bind them.
        :ok = AMQP.Exchange.declare(state.channel, @exchange, :direct)
        {:ok, _consumer_and_msg_info} = AMQP.Queue.declare(state.channel, state.queue)
        :ok = AMQP.Queue.bind(state.channel, state.queue, @exchange, routing_key: state.queue)
    end

    defp via_tuple(chatroom) do
        {:via, Registry, {MyRegistry, {:notifications, chatroom}}}
    end

    defp get_id(chatroom) do
        [head | _] = Registry.lookup(MyRegistry, {:notifications, chatroom})
        elem(head, 0)
    end
end