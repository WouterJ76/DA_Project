defmodule TwitterClone.ChatApp.NotificationPublisher do
    use GenServer

    alias TwitterClone.ChatApp.{MyRegistry}

    @channel :chat_app_channel
    @exchange "notification-server"
  
    @me __MODULE__
  
    @enforce_keys [:channel]
    defstruct [:channel, :queue]
  
    #########
    ## API ##
    #########
  
    def start_link(chatroom), do: GenServer.start_link(@me, chatroom <> "-notifications", name: via_tuple(chatroom))

    def send_notification(chatroom) do
        get_id(chatroom)
        |> GenServer.call(:send_notification)
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
    def handle_call(:send_notification, _, %@me{channel: c, queue: q} = state) do
        payload = Jason.encode!(%{command: "send_notification"})
        :ok = AMQP.Basic.publish(c, @exchange, q, payload)
        {:reply, :notification_send, state}
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