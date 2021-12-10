defmodule TwitterClone.UserApp.ChatSessiePublisher do
    use GenServer

    alias TwitterClone.UserApp.{MyRegistry}

    @channel :chat_app_channel
    @exchange "chatapp-server"
    @me __MODULE__

    #########
    ## API ##
    #########
  
    @enforce_keys [:channel]
    defstruct [:channel, :queue]
  
    def start_link(chatroom), do: GenServer.start_link(@me, chatroom, name: via_tuple(chatroom))
    
    def create_chatroom(chatroom) do
        get_id(chatroom)
        |> GenServer.call(:create_chatroom)
    end
    
    def send_message(chatroom, sender, message) do
        get_id(chatroom)
        |> GenServer.call({:send_message, sender, message})
    end

    ###############
    ## Callbacks ##
    ###############

    @impl true
    def init(chatroom) do
        {:ok, amqp_channel} = AMQP.Application.get_channel(@channel)
        state = %@me{channel: amqp_channel, queue: chatroom}
        rabbitmq_setup(state)
        {:ok, state}
    end

    @impl true
    def handle_call(:create_chatroom, _, %@me{channel: c, queue: q} = state) do
        payload = Jason.encode!(%{command: "create_chatroom"})
        :ok = AMQP.Basic.publish(c, @exchange, q, payload)
        {:reply, q, state}
    end

    @impl true
    def handle_call({:send_message, sender, message}, _, %@me{channel: c, queue: q} = state) do
        payload = Jason.encode!(%{command: "send_message", sender: sender, message: message})
        :ok = AMQP.Basic.publish(c, @exchange, q, payload)
        {:reply, :message_send_to_queue, state}
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
        {:via, Registry, {MyRegistry, {:chatroom, chatroom}}}
    end

    defp get_id(chatroom) do
        [head | _] = Registry.lookup(MyRegistry, {:chatroom, chatroom})
        elem(head, 0)
    end
end