defmodule TwitterClone.UserApp.UserManager do
    use GenServer

    alias TwitterClone.UserApp.{User, UserDynSup}

    @me __MODULE__
    defstruct users: %{}

    def start_link(args) do
        GenServer.start_link(@me, args, name: @me)
    end

    def add_user(username) do
        GenServer.call(@me, {:create_user, username})
    end

    def list_users(), do: GenServer.call(@me, :list_users)

    @impl true
    def init(_args), do: {:ok, %@me{}}

    # @impl true
    def handle_cast() do
        
    end

    @impl true
    def handle_call({:create_user, username}, _from, %@me{} = state) do
        case Map.has_key?(state.users, username) do
        true ->
            {:reply, {:error, :already_exists}, state}

        false ->
            response = DynamicSupervisor.start_child(UserDynSup, {User, [username: username]})
            new_users = Map.put_new(state.users, username, %{username: username})
            {:reply, response, %{state | users: new_users}}
        end
    end

    @impl true
    def handle_call(:list_users, _from, state) do
        {:reply, state.users, state}
    end

    # @impl true
    def handle_continue() do
        
    end
end