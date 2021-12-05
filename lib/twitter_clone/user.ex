defmodule TwitterClone.User do
    use GenServer

    @me __MODULE__

    defstruct username: nil, friends: %{}

    def start_link(args) do
        username = args[:username] || raise "No username found \":username\""
        GenServer.start_link(@me,username, name: via_tuple(username))
    end

    def add_friend(uid, friend) do
        uid
        |> via_tuple()
        |>GenServer.call({:add_friend, friend})
    end

    def list_friends(), do: GenServer.call(@me, :list_friends)

    @impl true
    def init(args) do
        {:ok, args}
    end

    @impl true
    def handle_call({:add_friend, friend}, state) do
        new_state = %{state | friends: [friend | state.friends]}
        {:reply, new_state}
    end

    def handle_call(:list_friends, _from, state) do
        {:reply, state.friends, state}
    end
    # @impl true
    # def handle_call(:empty, _from, %@me{} = state) do
    #     # Logger.debug("#{inspect(self())}: I'm being emptied!")
    #     {:reply, :ok, %{state | percentage: 0}, {:continue, :report}}
    # end

    # @impl true
    # def handle_info(:add_garbage, %@me{} = state) do
    #     # {:noreply, %{state | percentage: state.percentage + 10}, {:continue, :report}}
    # end

    # @impl true
    # def handle_continue(:report, %@me{} = state) do
    #     # ManagerApproach.GarbageCanManager.report_garbage_level(state.personal_id, state.percentage)
    #     # {:noreply, state}
    # end

    defp via_tuple(username) do
        {:via, Registry, {TwitterClone.MyRegistry, {:user, username}}}
    end
    
end