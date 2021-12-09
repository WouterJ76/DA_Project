defmodule TwitterClone.UserApp.User do
    use GenServer

    @me __MODULE__

    #########
    ## API ##
    #########

    def start_link(username) do
        GenServer.start_link(@me, username, name: via_tuple(username))
    end

    ###############
    ## Callbacks ##
    ###############

    @impl true
    def init(username) do
        state = %{username: username}
        {:ok, state}
    end

    ######################
    ## Helper functions ##
    ######################

    defp via_tuple(username) do
        {:via, Registry, {TwitterClone.UserApp.MyRegistry, {:user, username}}}
    end
end