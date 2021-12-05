defmodule UserApp.User do
    use GenServer

    @me __MODULE__

    defstruct username: nil

    def start_link(args) do
        username = args[:username] || raise "No username found \":username\""
        GenServer.start_link(@me,username, name: via_tuple(username))
    end

    @impl true
    def init(args) do
        {:ok, args}
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
        {:via, Registry, {UserApp.MyRegistry, {:user, username}}}
    end
    
end