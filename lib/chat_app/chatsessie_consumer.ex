defmodule TwitterClone.ChatApp.ChatSessieConsumer do
    use GenServer
    use AMQP

    @channel :chat_app_channel
    @exchange "chatapp-server"
    @me __MODULE__

    #########
    ## API ##
    #########
  
    @enforce_keys [:channel]
    defstruct [:channel, :queue]
  
    def start_link(chatroom), do: GenServer.start_link(@me, chatroom, name: String.to_atom("consumer: #{chatroom}"))

    ###############
    ## Callbacks ##
    ###############
  
    def init(chatroom) do
      {:ok, amqp_channel} = AMQP.Application.get_channel(@channel)
      state = %@me{channel: amqp_channel, queue: chatroom}
      rabbitmq_setup(state)
      {:ok, state}
    end
  
    def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, %@me{} = state) do
      {:noreply, state}
    end
  
    def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, %@me{} = state) do
      {:stop, :normal, state}
    end
  
    def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, %@me{} = state) do
      {:noreply, state}
    end
  
    def handle_info({:basic_deliver, payload, meta_info}, %@me{} = state) do
      payload
      |> Jason.decode!()
      |> proces_message(meta_info.delivery_tag, state)
  
      {:noreply, %@me{} = state}
    end
  
    ######################
    ## Helper functions ##
    ######################
  
    defp proces_message(%{"command" => "create_chatroom"}, tag, state) do
      TwitterClone.ChatApp.ChatManager.create_chatroom(state.queue)
      Basic.ack(state.channel, tag)
    end

    defp proces_message(%{"command" => "send_message", "sender" => sender, "message" => message}, tag, state) do
      TwitterClone.ChatApp.Chat.add_message(state.queue, sender, message)
      Basic.ack(state.channel, tag)
    end
  
    defp rabbitmq_setup(%@me{} = state) do
      :ok = AMQP.Exchange.declare(state.channel, @exchange, :direct)
      {:ok, _consumer_and_msg_info} = AMQP.Queue.declare(state.channel, state.queue)
      :ok = AMQP.Queue.bind(state.channel, state.queue, @exchange, routing_key: state.queue)
      :ok = Basic.qos(state.channel, prefetch_count: 1)
      {:ok, _unused_consumer_tag} = Basic.consume(state.channel, state.queue)
    end
  end