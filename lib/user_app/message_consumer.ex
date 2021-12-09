defmodule TwitterClone.UserApp.MessageConsumer do
    use GenServer
    use AMQP
  
    @channel :chat_app_channel
    @exchange "user-server"
    @me __MODULE__

    #########
    ## API ##
    #########
  
    @enforce_keys [:channel]
    defstruct [:channel, :queue]
  
    def start_link(username), do: GenServer.start_link(@me, username, name: @me)

    ###############
    ## Callbacks ##
    ###############
  
    def init(username) do
      {:ok, amqp_channel} = AMQP.Application.get_channel(@channel)
      state = %@me{channel: amqp_channel, queue: username}
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
      # |> proces_message(meta_info.delivery_tag, state)
      |> IO.puts()
  
      {:noreply, %@me{} = state}
    end
  
    ######################
    ## Helper functions ##
    ######################
  
    defp rabbitmq_setup(%@me{} = state) do
      :ok = AMQP.Exchange.declare(state.channel, @exchange, :direct)
      {:ok, _consumer_and_msg_info} = AMQP.Queue.declare(state.channel, state.queue)
      :ok = AMQP.Queue.bind(state.channel, state.queue, @exchange, routing_key: state.queue)
      :ok = Basic.qos(state.channel, prefetch_count: 1)
      {:ok, _unused_consumer_tag} = Basic.consume(state.channel, state.queue)
    end
  end