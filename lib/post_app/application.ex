defmodule TwitterClone.PostApp.Posts do
  use GenServer

  @me __MODULE__

  #########
  ## API ##
  #########

  def start_link(_args) do
      GenServer.start_link(@me, :no_opts, name: @me)
  end

  ###############
  ## Callbacks ##
  ###############

  @impl true
  def init(:no_opts) do
      state = %{posts: []}
      {:ok, state}
  end

  ######################
  ## Helper functions ##
  ######################


end