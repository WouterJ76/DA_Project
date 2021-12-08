defmodule TwitterClone.UserApp.MessageConsumer do
    use GenServer
    use AMQP
  
    require IEx
  
    @channel :chat_app_channel
    @exchange "user-server"
    @me __MODULE__
  
    @enforce_keys [:channel]
    defstruct [:channel, :queue]
  
    def start_link(username), do: GenServer.start_link(@me, username, name: @me)
  
    def init(username) do
      {:ok, amqp_channel} = AMQP.Application.get_channel(@channel)
      state = %@me{channel: amqp_channel, queue: username}
      rabbitmq_setup(state)
      {:ok, state}
    end
  
    # Confirmation sent by the broker after registering this process as a consumer
    def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, %@me{} = state) do
      # do nothing
      {:noreply, state}
    end
  
    # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
    def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, %@me{} = state) do
      # do nothing
      {:stop, :normal, state}
    end
  
    # Confirmation sent by the broker to the consumer process after a Basic.cancel
    def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, %@me{} = state) do
      # do nothing
      {:noreply, state}
    end
  
    def handle_info({:basic_deliver, payload, meta_info}, %@me{} = state) do
      payload
      |> Jason.decode!()
      # |> proces_message(meta_info.delivery_tag, state)
      |> IO.puts()
  
      {:noreply, %@me{} = state}
    end
  
    ## Helper functions ##
  
    # defp proces_message(%{"command" => "create", "name_can" => can_id} = msg, tag, state) do
    #   result = ManagerApproach.GarbageCanManager.add_garbage_can(can_id)
    #   Basic.ack(state.channel, tag)
  
    #   # Note: not always necessary to send the whole request back. If frontend would keep track of the request unique tag, then you should only send that tag and the result back in order to reduce bandwidth.
    #   case result do
    #     {:ok, _} ->
    #       %{request: msg, result: "succeeded"}
    #       |> ManagerApproach.WebserverPublisher.send_message()
  
    #     {:error, :already_exists} ->
    #       %{request: msg, result: "failed", reason: "Already exists"}
    #       |> ManagerApproach.WebserverPublisher.send_message()
    #   end
    # end
  
    defp rabbitmq_setup(%@me{} = state) do
      # Create exchange, queue and bind them.
      :ok = AMQP.Exchange.declare(state.channel, @exchange, :direct)
      {:ok, _consumer_and_msg_info} = AMQP.Queue.declare(state.channel, state.queue)
      :ok = AMQP.Queue.bind(state.channel, state.queue, @exchange, routing_key: state.queue)
  
      # Limit unacknowledged messages to 1. THIS IS VERY SLOW! Just doing this for debugging
      :ok = Basic.qos(state.channel, prefetch_count: 1)
  
      # Register the GenServer process as a consumer. Consumer pid argument (3rd arg) defaults to self()
      {:ok, _unused_consumer_tag} = Basic.consume(state.channel, state.queue)
    end
  end